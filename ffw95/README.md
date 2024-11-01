# A solution to Frosty Friday Week 95

[Frosty Friday][fros] is a weekly Snowflake challenge series
created by Christopher Marland and Mike Droog.
These challenges can be a lot of fun so be sure to take a look!

This is my solution to [Frosty Friday Week 95][ffw95].

In this challenge we need to upload a file
with Python code to Snowflake
and then use that file from a stored procedure.

We start by creating that file on our computer
and name it `congrats.py` for example.
It has the following contents:

```python
def success():
    return 'Congratulations!'
```

We need the full path to this file.
If we are working on a Mac,
have a user named `Zeven` and saved the file to the Desktop,
we could end up with the following full path:

```txt
/Users/Zeven/Desktop/congrats.py
```

We need to make an *file* Uniform Resource Identifier (URI)
from this path.
In this case that means that we have to
prepend the URI *scheme* `file` to the path
and separate it from our path with `://`.
We get `file:///Users/Zeven/Desktop/congrats.py`
as the file URI in this case.

Now we need to upload this file to a stage.
We can use any stage for this,
but we are going for our own user stage: `@~`.
Keep in mind that other users in your account won't
be able to access that stage (or any files it contains).
If that is what you want,
you should use a named stage, for example.

We need to use a `PUT` statement with
our file URI and the stage we want to use.
We get the following statement:

```sql
PUT file:///Users/Zeven/Desktop/congrats.py @~;
```

Note that this works on VSCODE with the official Snowflake Extension.
We cannot do this from the Web UI (Snowsight),
where we would need to use the GUI.

If we have successfully uploaded our file to our user stage,
we can continue creating the stored procedure:

```sql
CREATE OR REPLACE PROCEDURE
    frosty_challenge()
    RETURNS string
    LANGUAGE python
    PACKAGES=('snowflake-snowpark-python')
    imports=('@~/congrats.py')
    HANDLER = 'func'
    RUNTIME_VERSION=3.8
    AS
$$
import congrats

def func(session):
    return congrats.success()
$$
;
```

We need 2 things to be able to use our Python file:

1.  The `imports=('@~/congrats.py')` line shows the name of our file
    and the stage it is in (`@~`).
1.  `import congrats` imports the file as a Python module.

Now that we have access to the code in the file,
we can execute our previously creating function `success()`
and return it from our stored procedure.
Be sure to use the right namespace for our function:
`congrats.success()` tells Python to look for
the function `success()` in the `congrats` modole.

Finally, we can call the stored procedure:

```sql
CALL frosty_challenge();
```

And that's it!

[fros]: https://frostyfriday.org/
[ffw95]: https://frostyfriday.org/blog/2024/05/24/week-95-intermediate/
