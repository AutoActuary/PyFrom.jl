# PyFrom.jl

This module adds extra python import syntax to PyCall, more specifically the syntax:
```
from module.submodule import a, b, sea as c
```

### Example
```
Using PyFrom
@pyfrom math import inf as py∞, pi as pyπ, tau
```

