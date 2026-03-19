var rootCommand = new RootCommand("dostar — Dostar modular monolith CLI");

rootCommand.Subcommands.Add(NewProjectCommand.Build());

return await rootCommand.Parse(args).InvokeAsync();
