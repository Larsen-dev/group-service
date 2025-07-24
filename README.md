# 🧑‍🤝‍🧑 group-service 🧑‍🤝‍🧑

# ©️ COPYRIGHT ©️
PLEASE INSERT THIS IF YOU WILL MODIFICATE STANDART API.

GroupService is a Knit based service writted by Larsen-dev.
All modifications are welcomed.

# Important
GroupService was not a serious project, just a practise, so if you find any problems please connect me.

# 📌 Short API description 📌
@class Group
  - :AddMember(self: Group, member: Player) -> ()
  - :KickMember(self: Group, member: Player) -> ()
  - :Disband(self: Group) -> ()
  - :TeleportGroup(self: Group, placeId: number, teleportOptions: TeleportOptions) -> ()

@service GroupService
  - :CreateGroup: (self: GroupService, owner: Player) -> (group: Group)
  - :GetGroupFromOwner: (self: GroupService, owner: Player) -> (group: Group | nil)
  - :GetGroupMembers: (self: GroupService, group: Group) -> ({  Player  })

Dependecies:
  - Promise ^latest
  - Knit ^latest
  - Roblox Studio API
