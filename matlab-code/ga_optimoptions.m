function mret = ga_optimoptions()
    mret.Algorithm = 'interior-point';
    mret.CheckGradients= 0;
    mret.ConstraintTolerance= 1.0000e-06;
    mret.Display= 'final';
    mret.FiniteDifferenceStepSize= 'sqrt(eps)';
    mret.FiniteDifferenceType= 'forward';
    mret.HessianApproximation= 'bfgs';
    mret.HessianFcn= [];
    mret.HessianMultiplyFcn= [];
    mret.HonorBounds= 1;
    mret.MaxFunctionEvaluations= 3000;
    mret.MaxIterations= 1000;
    mret.ObjectiveLimit= -1.0000e+20;
    mret.OptimalityTolerance= 1.0000e-06;
    mret.OutputFcn= [];
    mret.PlotFcn= [];
    mret.ScaleProblem= 0;
    mret.SpecifyConstraintGradient= 0;
    mret.SpecifyObjectiveGradient= 0;
    mret.StepTolerance= 1.0000e-10;
    mret.SubproblemAlgorithm= 'factorization';
    mret.TypicalX= 'ones(numberOfVariables,1)';
    mret.UseParallel= 'never';
    
end