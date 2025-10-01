---
title: Documentation
layout: default
---


The staircase algorithm adjusts a parameter value (v) based on the animal's performance:

- Correct trials: Increase by s
- Incorrect trials: Decrease by m

## Mathematical Derivation

### Fixed Point Analysis

The parameter value reaches a fixed point when the performance P (probability correct) satisfies:

```matlab
P * s = (1 - P) * m
```

This can be rearranged to:

```matlab
m = P * s / (1 - P)
s = (1 - P) * m / P
```

The fixed point is stable if:

- The s direction decreases performance
- The m direction increases performance

### Parameter Adjustment

When targeting a specific performance P with current performance p:

```matlab
dv = p * s - (1 - p) * m
   = s * (p - (1 - p) * P / (1 - P))
   = s * (p - P) / (1 - P)
```

### Example

For a target performance of 75% with current performance of 80%:

```matlab
dv = s * (0.8 - 0.75) / (1 - 0.75)
   = s / 5
```

To move from 8 to 5.66 in log space over 750 trials:

1. Dv = 8/5.66 = 1.4134
2. This requires 750 steps of s/5, or 150 steps of s
3. 1.4134^(1/150) = 1.00231

Therefore:

- Divide v by 1.00231 every hit
- Multiply v by 1.00927 (1.00231^4) every miss

## Implementation Notes

1. The algorithm automatically adjusts to maintain the target performance
2. The step size (s) can be modified to control the rate of convergence
3. The algorithm is stable and will converge to the target performance level
