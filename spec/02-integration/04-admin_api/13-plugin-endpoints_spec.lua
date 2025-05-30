local helpers = require "spec.helpers"


for _, strategy in helpers.each_strategy() do

describe("Admin API endpoints added via plugins #" .. strategy, function()
  local client

  setup(function()
    local bp = helpers.get_db_utils(strategy, {
      "plugins",
    }, {
      "admin-api-method"
    })

    bp.plugins:insert({
      name = "admin-api-method",
    })

    assert(helpers.start_kong({
      database = strategy,
      nginx_conf = "spec/fixtures/custom_nginx.template",
      plugins = "admin-api-method",
    }))
    client = helpers.admin_client()
  end)

  teardown(function()
    if client then
      client:close()
    end
    helpers.stop_kong()
  end)

  it("a method without an explicit exit does not add Lapis output", function()
    local res = assert(client:send {
      method = "GET",
      path = "/method_without_exit",
      headers = { ["Content-Type"] = "application/json" }
    })
    local body = assert.res_status(201, res)
    assert.same("hello", body)
  end)

  it("nested parameters can be parsed correctly when using form-urlencoded requests", function()
    local res = assert(client:send{
      method = "POST",
      path = "/parsed_params",
      body = ngx.encode_args{
        ["items[1]"] = "foo",
        ["items[2]"] = "bar",
      },
      headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    })
    local body = assert.res_status(200, res)
    assert.same('{"items":["foo","bar"]}', body)
  end)
end)

end
