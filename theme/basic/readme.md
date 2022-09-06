# Basic Theme

This folder contains a basic theme that customise the look and feel of DbMan query results served over HTTP.

Whenever DbMan is launched as an HTTP server, and a query is run, DbMan can fetch a theme in a repository and merge its 
contents with the returned web page.

The *theme* must be created as a sub-folder (in this case "basic") within the "theme" folder and with one or more of the 3 files as shown below:
- **style.css**: an optional style sheet which overrides the content of DbMan's initial stylesheet.
- **header.html**: an optional web page header.
- **footer.html**: an optional web page footer.

Then, to tell DbMan to use the *theme* simply set the **Theme** variable in DbMan's configuration to the name of the theme required:

```bash
$ ./dbman config set Theme basic
```

Now launch DbMan as an HTTP server:
```bash
$ ./dbman serve
```

Launch a browser and navigate to the [/db/query/version-history](http://localhost:8085/db/query/version-history) to see the 
result with the new theme.