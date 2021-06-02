# PyFrom.jl

This module adds the `from module import x as y` syntax to PyCall.

### Example usage
```
using PyFrom
@pyfrom math import inf as py∞, pi as pyπ, tau
```

