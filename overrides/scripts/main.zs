// This file contains most of the CraftTweaker scripts for the modpack. Most of
// this is for the Pumpking's Scavenger hunt.
import crafttweaker.api.entity.attribute.AttributeModifier;
import crafttweaker.api.entity.type.player.ServerPlayer;
import crafttweaker.api.item.IItemStack;
import crafttweaker.api.item.component.ItemAttributeModifiers;
import crafttweaker.api.text.Component;
import crafttweaker.api.world.ServerLevel;
import crafttweaker.neoforge.api.event.advancement.AdvancementEarnEvent;
import crafttweaker.neoforge.api.event.interact.RightClickBlockEvent;
import crafttweaker.neoforge.api.event.interact.RightClickItemEvent;

// Item modifiers for the Pumpking's Crown, the reward for completing the
// scavenger hunt.
val modifiers = ItemAttributeModifiers.builder()
    .add(
        <attribute:minecraft:generic.armor>,
        AttributeModifier.create(<resource:spookyjam:crown_protection>, 13.0, <constant:minecraft:attribute/operation:add_value>),
        <constant:minecraft:equipmentslot/group:head>
    )
    .add(
        <attribute:minecraft:generic.armor_toughness>,
        AttributeModifier.create(<resource:spookyjam:crown_toughness>, 0.13, <constant:minecraft:attribute/operation:add_multiplied_total>),
        <constant:minecraft:equipmentslot/group:head>
    )
    .add(
        <attribute:minecraft:player.sneaking_speed>,
        AttributeModifier.create(<resource:spookyjam:crown_sneaky>, 1.30, <constant:minecraft:attribute/operation:add_multiplied_total>),
        <constant:minecraft:equipmentslot/group:head>
    )
    .add(
        <attribute:minecraft:generic.luck>,
        AttributeModifier.create(<resource:spookyjam:crown_luck>, 1.30, <constant:minecraft:attribute/operation:add_multiplied_total>),
        <constant:minecraft:equipmentslot/group:head>
    )
.build();

// The crown item that is awarded for completing the scavenger hunt. This is
// also used as a predicate to check if an item is the crown. We are using a
// java o' lantern instead of a pumpkin to avoid the blur HUD effect.
val pumpkinCrown = <item:minecraft:jack_o_lantern>.withJsonComponent(<componenttype:minecraft:lore>, [Component.literal("Right click to equip the crown!").withStyle(<constant:minecraft:formatting:dark_gray>).withStyle(style => style.withItalic(false)).asIData()]).withAttributeModifiers(modifiers).withMaxStackSize(1).withItemName(Component.literal("Pumpking's Crown").withStyle(<constant:minecraft:formatting:gold>));

// A list of advancement IDs for all item advancements in the scavenger hunt.
val huntAdvancements = [<resource:spookyjam:scavenger_hunt/item_1>, <resource:spookyjam:scavenger_hunt/item_2>, <resource:spookyjam:scavenger_hunt/item_2>, <resource:spookyjam:scavenger_hunt/item_3>, <resource:spookyjam:scavenger_hunt/item_4>, <resource:spookyjam:scavenger_hunt/item_5>, <resource:spookyjam:scavenger_hunt/item_6>, <resource:spookyjam:scavenger_hunt/item_7>, <resource:spookyjam:scavenger_hunt/item_8>, <resource:spookyjam:scavenger_hunt/item_9>, <resource:spookyjam:scavenger_hunt/item_10>, <resource:spookyjam:scavenger_hunt/item_11>, <resource:spookyjam:scavenger_hunt/item_12>, <resource:spookyjam:scavenger_hunt/item_13>];

// The ID of the advancement awared when the player completes the scavenger hunt.
val completionAdvId = <resource:spookyjam:scavenger_hunt/all_items>;

// This code will be ran every time a player earns an advancement.
events.register<AdvancementEarnEvent>(event => {

    // Check if the player has completed the hunt, and awards them the crown.
    if (event.advancement.id == completionAdvId) {
        event.entity.give(pumpkinCrown);
        return;
    }
  
    // If any other advancement is earned, check if they have all of the
    // required advancements and award the completion advancement if they do.
    val player = event.entity;
    val level = player.level;
    if (player is ServerPlayer && level is ServerLevel) {
        val sp = player as ServerPlayer;
        val sl = level as ServerLevel;
        val server = sl.server;
        val completeAdv = server.advancements[completeAdv];
        // Checks if the player already has the advancement, so they don't get
        // it again.
        if (!sp.advancements.getOrStartProgress(completeAdvId).done) {
            // Check if they have completed all of the required advancements.
            for (advancement in huntAdvancements) {
                if (!sp.advancements.getOrStartProgress(server.advancements[advancement]).done) {
                    return;
                }
            }
            // Awards the completion advancement. The complete_quests criteria 
            // is defined as impossible in the advancement JSON and can only be
            // completed by manually awarding it.
            sp.advancements.award(completeAdv, "complete_quests");
        }
    }
});

// The crown is an item that is not normally equippable. By intercepting the 
// right click event we can forcefully equip the item to the slot. This is 
// something that could be avoided in newer versions of Minecraft by using 
// the equipable component.
events.register<RightClickItemEvent>(event => {
    if (pumpkinCrown.matches(event.itemStack)) {
        event.cancel();
        if (!event.entity.level.isClientSide && !event.entity.hasItemInSlot(<constant:minecraft:equipmentslot:head>) && event.hand != <constant:minecraft:interactionhand:off_hand>) {
            event.entity.setItemSlot(<constant:minecraft:equipmentslot:head>, event.itemStack.copy());
            event.itemStack.asMutable().shrink();
        }
    }
});

// The crown is a block item and would lose all of its data if the player were
// to place it into the world. While there is a component for specifying which
// blocks an item can be placed on, this component only works if the player is
// also in adventure mod. We may add a general purpose component in a mod like
// datamancy in the future, but for now a simple event cancel is more than 
// enough.
events.register<RightClickBlockEvent>(event => {
    if (pumpkinCrown.matches(event.itemStack)) {
        event.cancel();
    }
});