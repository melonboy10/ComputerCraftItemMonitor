# Seedless Item Monitor
Seedless Item Monitor is an item monitoring system (duh) made with ComputerCraft for 1.16.5

## Setup
Copy the pastbin command below and run it to start the installer.
If the computer has a `startup.lua` file already present then it will be overwritten so it is recomended to use a fresh computer.

`pastebin run 298376482976349238649`

This will install the full system, just restart the computer to setup the computer.

There are requirements for the system though.
- Needs to be an advanced computer / monitor
- Needs to have at least 1 monitor attched (6 minimum for the hubs ie. 3x2)
- Needs to have a wireless modem. This can be a Regular or Ender Modem but keep in mind the range limitations with the regular one.
- For Nodes there needs to be a container on top of the computer (Fluids included)
    - For [Storage Drawers](https://www.curseforge.com/minecraft/mc-mods/storage-drawers), because ComputerCraft can't interface with them, you need the [Advanced Peripherals](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) mod installed
    - Place a block reader on top of the computer pointing into a Storage Drawer

Keep in mind the system was not intended for large scale computercraft networks because it uses the broadcast channel to transmit information so this is likely incompatable with anything that broadcasts messages