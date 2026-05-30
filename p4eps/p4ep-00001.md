# P4Runtime: Global Actions for ActionProfileActionSets

Authors: @matthewtlam
Contributors: @kheradmand, @smolkaj, @jonathan-dilorenzo

## Objective
Support global metadata setting for ActionProfileActionSets in P4.

## Motivation
In the P4Runtime API, the ActionProfileActionSet is used to program actions associated with an action profile, which is typically used for modeling the forwarding behaviors for ECMP/WCMP. Each ActionProfileAction represents a weighted path with an action that needs to be executed (e.g. set nexthop or encap) for a WCMP member. P4 currently does not have a native way to provide a global parameter or action that applies on all paths of an ActionProfileActionSet. A common scenario that would require this is setting a metadata for any path taken by the ActionProfile (e.g. setting a route_metadata).

### Current Ways to Represent a global metadata
#### Option 1: Action Composition
Define new actions in the P4 program that combine the desired "global" logic with each specific member action. For example, adding a global parameter of route_metadata to every single action.

Pros:
- Applies actions sequentially to get desired forwarding behavior

Cons:
- Will require additional checks to make sure that the global parameter is consistent across all actions in the action set, which is not current expressible in P4Runtime
- Redundancy of defining unnecessary actions or additional parameters

#### Option 2: Two P4 Tables
Use a primary table with an action profile behaves “normally” and use another table for lookup before or after the primary table using the action profile to apply the “global” logic.

Pros:
- Applies actions sequentially to get desired forwarding behavior

Cons:
- Cannot atomically update 2 tables in lock step
- May take up additional resources (depending on hardware)
- Changes the pipeline structure

## Design Options

### Option 1: P4Runtime Native Support (Implementation reflected in this PR)
Extend the P4Runtime API to support global action in action sets. The proposed global_action in ActionProfileActionSet adds a native mechanism for global parameters. The global_action should behave as a "base" action that is logically composed with the selected member action. Semantically, it functions as a pre-action to the existing member-specific logic, effectively providing the shared context needed for the pipeline to process any selected ActionProfileAction. 

Pros
- Reduced redundancy and clearer intent by not specifying the same common action parameters for every member in the group
- Save space since we do not need to use another table to represent this and instead have one action rather than sending multiple requests
- Clearly defined P4 types for the global parameters

Cons
- Only applies to ActionSelectors with the oneshot annotation

#### P4 Runtime Changes  
```
// p4runtime.proto
message TableAction {
  oneof type {
    Action action = 1;
    uint32 action_profile_member_id = 2;
    uint32 action_profile_group_id = 3;
    ActionProfileActionSet action_profile_action_set = 4;
  }
}

message Action {
  uint32 action_id = 1;
  message Param {
    uint32 param_id = 2;
    bytes value = 3;
  }
  repeated Param params = 4;
}

message ActionProfileActionSet {
  repeated ActionProfileAction action_profile_actions = 1;
    Action global_action = 5;             <-------------- Added line
  ...
}
```

#### P4Info Changes
Ideally there should be a way to specify that an action defined for a table can only be used as a global action. To specify this in P4 code, we propose to add an annotation (e.g., @globalaction) on the actions list in the table declaration.  This allows the target to enforce that the designated action can be used only as a global action in the ActionProfileActionSets.  

Example of using the annotation: 
```
  ActionSelector(...) wcmp_group_selector;
  table wcmp_group_table {
    key = {
      group_id : exact;
      selector_input : selector;
    }
    actions = {
      set_nexthop_id;
      @globalonly global_action;           <------------------ Using the new annotation
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    implementation = wcmp_group_selector;
  }
```

Ideally, this can be reflected in Scope used in ActionRef by the P4 compiler:
```
// p4info.proto
message ActionRef {
  uint32 id = 1;
  enum Scope {
    TABLE_AND_DEFAULT = 0;
    TABLE_ONLY = 1;
    DEFAULT_ONLY = 2;
    GLOBAL_ONLY = 3;         <-------------------Added line
  }
  Scope scope = 3;
  repeated string annotations = 2;
  // Optional. If present, the location of `annotations[i]` is given by
  // `annotation_locations[i]`.
  repeated SourceLocation annotation_locations = 5;
  repeated StructuredAnnotation structured_annotations = 4;
}
```

Alternatively or as a short term solution, the annotation can be embedded in annotations repeated field instead of first class support in p4info. 

### Option 2: Metadata
Embed the global metadata setting in the table entry’s metadata. 

Pros:
- Metadata is free-form so the global data can be manipulated and stored

Cons:
- Strictly not P4Runtime standard compliant because 
- Switch and controller need to agree on schema of metadata
- Type/encoding is not captured by P4Runtime specification

