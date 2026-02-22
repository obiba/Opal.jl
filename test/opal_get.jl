using Opal
using Opal: Opal
using Test
using HTTP: HTTP

@testset "login" begin
    opal = opal_login(;
        username="administrator", password="password", url="https://opal-demo.obiba.org"
    )

    profiles_url = Opal._url(opal, "datashield", "profiles")
    acceptType = "application/json"

    r = HTTP.request(
        "GET",
        profiles_url;
        query="",
        headers=Dict("Accept" => acceptType),
        logerrors=false,
        times=3,
        # config = opal.config,
    )

    table_url = Opal._url(opal, "datasource", "CNSIM", "table", "CNSIM1")
    r2 = HTTP.request(
        "GET",
        table_url;
        query="",
        headers=Dict("Accept" => acceptType),
        logerrors=false,
        times=3,
        # config = opal.config,
    )
end

# #' Get a table of a datasource
# #'
# #' @family datasource functions
# #' @param opal Opal object.
# #' @param datasource Name of the datasource.
# #' @param table Name of the table in the datasource.
# #' @param counts Flag to get the number of variables and entities (default is FALSE).
# #' @examples
# #' \dontrun{
# #' o <- opal.login('administrator','password', url='https://opal-demo.obiba.org')
# #' opal.table(o, 'CNSIM', 'CNSIM1')
# #' opal.logout(o)
# #' }
# #' @export
# opal.table <- function(opal, datasource, table, counts=FALSE) {
#   if (counts) {
#     opal.get(opal, "datasource", datasource, "table", table, query=list(counts="true"));
#   } else {
#     opal.get(opal, "datasource", datasource, "table", table);
#   }
# }
