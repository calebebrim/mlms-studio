function gaopt = def_gaopt()
gaopt = gaoptimset;
gaopt.MutationFcn = {@mutationuniform,0.70};
gaopt.PopulationSize = 10;
gaopt.StallTimeLimit = 100000;
gaopt.Generations = 100;
gaopt.Display = 'none';
gaopt.PopulationType = 'bitstring';
end