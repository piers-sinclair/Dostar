var rootCommand = new RootCommand("dostar — Dostar modular monolith CLI");

rootCommand.Subcommands.Add(AddModuleCommand.Build());
rootCommand.Subcommands.Add(RemoveModuleCommand.Build());

return await rootCommand.Parse(args).InvokeAsync();
