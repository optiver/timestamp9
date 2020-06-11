In order to run the tests, build everything and make sure PG_REGRESS is found. Then run:

```
make regresscheck
```

To add new tests, either add them to an existing `.sql` file, or add a new `.sql` file.
Make sure to update the `.out` file in the `expected` directory with the expected output.

