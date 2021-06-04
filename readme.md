# DotEnv

A simple PowerShell module enabling loading of `.env` files into a PowerShell session. Takes inspiration from the node norm of [env files](https://www.freecodecamp.org/news/nodejs-custom-env-files-in-your-apps-fa7b3e67abe1/). It simply picks up your key value pairs from `.env`, and loads them into transient environment variables. They can be optionally cleaned up at the end of the session, or the session can just be destroyed.

## How To Use

Install, call.

### Install

`Find-Module dotenv`

`Install-Module dotenv`

### Use

```powershell
Import-Module dotenv
Set-DotEnv # loads from the local .env file
# code here
Remove-DotEnv # clears the variables that were loaded by set-dotenv
```

### Advanced scenarios

If you want to keep several .env files alongside your repo, you can use the path parameter to load a specific file.

```powershell
Import-Module dotenv
Set-DotEnv -Path ./env.staging
# code here
Remove-DotEnv
```

### Escaping

This module can handle values with an extra '=' in them, and can handle quoted strings (single and double). For more complex scenarios, it may be advisable to base64 encode the values, and then decode as they're needed.

## Coming Soon

- Allow append and prepend with `:=`/`=:` syntax
- Extra testing, especially around injection of 'bad' vars, because we're dealing with possible third-party input here

## Contributing

Contribs welcome, please put in a PR and notify @cloudyopspoet on Twitter that you've done it, as notifications don't always make it through from github.
