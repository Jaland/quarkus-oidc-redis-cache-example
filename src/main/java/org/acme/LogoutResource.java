package org.acme;

import io.quarkus.oidc.OidcSession;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;

@Path("/logout")
public class LogoutResource {

    @Inject
    OidcSession oidcSession;

    @GET
    @Authenticated
    @Produces(MediaType.TEXT_PLAIN)
    public Response logout(@QueryParam("global") String global) {
        // Local logout only - keeps Google session active
        oidcSession.logout().await().indefinitely();
        return Response.seeOther(URI.create("/logout/success")).build();
    }

    @GET
    @Path("/success")
    @Produces(MediaType.TEXT_PLAIN)
    public String logoutSuccess() {
        return "Successfully logged out. You can close this window or navigate back to the application.";
    }
}
