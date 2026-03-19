var rootCommand = new RootCommand("dostar — Dostar modular monolith CLI");

rootCommand.Subcommands.Add(AddModuleCommand.Build());

return await rootCommand.Parse(args).InvokeAsync();
