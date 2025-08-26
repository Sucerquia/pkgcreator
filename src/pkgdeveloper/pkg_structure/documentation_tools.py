import inspect
from importlib import import_module


# add2executable
def methods_in_class(module, class_name):
    """
    Shows the methods that are in a class.

    Parameters
    ==========
    module: str
        name of he module.
    class_name: str
        name of the class.

    Return
    ======
    (list) all modules in the class.
    """
    module = import_module(module)

    imported_class = getattr(module, class_name)

    # Get all methods of the class
    methods = [member[0] for member
               in inspect.getmembers(imported_class,
                                     predicate=inspect.isfunction)
               if member[0] != '__init__']
    for method in methods:
        print(method)
    return methods


# add2executable
def args_and_defaults(module, *args):
    """
    Takes a function and prints its parameters with their default values.

    Parameters
    ==========
    func:
        function that you want to extract the parameters and default values.
    module:
        module to extract arguments and defatuls.
    *args subclases or modules inside module.

    Return
    ======
    (str) set of arguments and defaults.
    """
    # Deprecated
    module = import_module(module)

    method = getattr(module, args[0])
    for func in args[1:]:
        method = getattr(method, func)

    signature = inspect.signature(method)

    output = f"\n ### {args[-1]}\n"
    for param_name, param in signature.parameters.items():
        if param.default != inspect.Parameter.empty:
            output += f"{param_name}: Default={param.default}\n"
        else:
            output += f"{param_name}:\n"
    output += "\n"
    return output


# add2executable
def function_doc(module, *args):
    """
    Takes a function and prints its documentation.

    Parameters
    ==========
    module:
        module to extract the documentation.
    *args subclases or modules inside module.

    Return
    ======
    (str) function documentation
    """
    module = import_module(module)

    method = getattr(module, args[0])
    for func in args[1:]:
        method = getattr(method, func)

    return method.__doc__
