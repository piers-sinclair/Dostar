var rootCommand = new RootCommand("dostar — Dostar modular monolith CLI");

return await rootCommand.Parse(args).InvokeAsync();
