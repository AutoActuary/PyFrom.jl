# PyFrom.jl

This module adds extra python import syntax to PyCall, more specifically the syntax:
```
from module import x, y, z as zee
```

### Example usage
```
Using PyFrom
@pyfrom math import inf as py∞, pi as pyπ, tau
```

