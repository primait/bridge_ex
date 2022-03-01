# `bridge_ex` - Roadmap

This document describes the current status and the upcoming milestones of the `bridge_ex` library.

| Status | Goal | Breaking | Card |
| :---: | :--- | :---: | :---: |
| ✔️ | Add a CHANGELOG | - | - |
| ✔️ | Add a ROADMAP for future developments | - | - |
| ❌ | [Support all possible outcomes of a GraphQL query](#support-all-possible-outcomes-of-a-graphql-query) | 💣 | - |
| ❌ | [Log queries safely](#log-queries-safely) | - | - |
| ❌ | [Use strings instead of atoms when deserializing GraphQL response](#use-strings-instead-of-atoms-when-deserializing-graphql-response) | 💣 | - |
| ❌ | [Flexible retry policy](#make-retry-policy-more-flexible) | - | [341](https://prima-assicurazioni-spa.myjetbrains.com/youtrack/issue/PLATFORM-341) |
| ❌ | [Exponential retry policy](#add-exponential-retry-policy) | - | - |

## Support all possible outcomes of a GraphQL query

A GraphQL query may return

- only `data` on success
- only `errors` with null `data` on error
- both `data` and `errors` on partial success/failure

Right now `bridge_ex` returns

- `{:ok, data}` if `errors` is present
- `{:error, errors}` if `errors` is present, regardless of whether `data` is null or not

In the future, we may want to support the case of partial response, probably just by returning the whole response and letting the caller deal with its contents.

## Log queries safely

If `log_query_on_error` option is enabled, both the query and its variables are logged, thus possibly leaking private data. In the future, we could remove the `variables` portion, allowing the caller to log the query even in `staging` or `production` without any risk.

## Use strings instead of atoms when deserializing GraphQL response

When deserializing the GraphQL response we convert all keys to atoms. While nothing bad has happened yet, this may lead to problems: atoms are not garbage collected and there is a limit to how many atoms one can have. In general, generating atoms dynamically is not a good practice, especially based on external input.

The change should be easy, just change the [following function](lib/graphql/utils.ex)

```elixir
def decode_http_response({:ok, %HTTPoison.Response{status_code: 200, body: body_string}}, _, _) do
 Jason.decode(body_string, keys: :atoms)
end
```

to convert keys to strings.

## Make retry policy more flexible

Improve the library by adding the ability to customize the retry policy.

On error, a retry function is called (if max attempts > 1), but right now the retry happens regardless of the error. This is a bit limiting since not all errors are transient and enabling the retry could lead to many needless requests.

A better approach would be to provide the user with a default retry mechanism and then a way to define a custom function to match errors and decide which to recover from, something like

```elixir
use BridgeEx.Graphql,
  endpoint: "http://my-endpoint",
  retry_options: [
    handler: fn
      {:error, "SOME_ERROR"} -> :retry
      {:error, "ANOTHER_ERROR"} -> :retry
      _ -> :stop
    end
  ]
```

or even at the call level

```elixir
use BridgeEx.Graphql,
  endpoint: "http://my-endpoint"

...

call("{ some { query } }", %{},
  retry_options: [
    handler: fn
      {:error, "SOME_ERROR"} -> :retry
      {:error, "ANOTHER_ERROR"} -> :retry
      _ -> :stop
    end
  ]
)
```

## Add exponential retry policy

As of now the retry policy is linear. It could be useful to implement an exponential retry strategy instead.
