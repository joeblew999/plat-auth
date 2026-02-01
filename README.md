# plat-auth

Authelia and casbin

## concept

an exact copy of google sign up and security that reusable for all Apps

https://github.com/authelia/authelia

authekia using coreosion to no internet failure effects anything , but also your sydtem alwats works offline.

web gui is authelia

---

https://github.com/casbin/casbin

cas bin runs in each app convertibg the user / roles to internal roles. simple CSV or whatever .

caddy proxy in mode ?

---

https://github.com/lldap/lldap

---

https://github.com/asalimonov/authelia-admin

see: 

https://g.co/gemini/share/c060c245d76a


To build this "mini-Google" architecture in Go, your "agent" (the developer or your code-gen assistant) needs a specific blueprint.
Here is the technical stack and the exact configuration files required to bridge Authelia (Identity) with Casbin (Permissions).
1. The Core Components
The agent needs to install these three pieces:
 * Authelia: The OIDC/Header provider (the "Bouncer").
 * Reverse Proxy (Traefik/Nginx): To pass headers to your app.
 * Go App with Casbin: The "Brain" that evaluates the headers.
2. The Model File (model.conf)
This is the "logic" file for Casbin. It tells Go how to interpret the roles and the requests.
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[role_definition]
g = _, _

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
# This logic says: "If user has a role (g) that matches a policy (p), 
# and the object/action match, then allow."
m = g(r.sub, p.sub) && keyMatch(r.obj, p.obj) && r.act == p.act

3. The Policy File (policy.csv)
This is where you actually map your Authelia Groups to your app's permissions.
# Permissions for the 'admin' group
p, group:admin, /api/admin/*, *
p, group:admin, /api/user/*, *

# Permissions for the 'developers' group
p, group:developers, /api/user/*, read
p, group:developers, /api/debug, read

# Role mappings (Usually these come dynamically from Authelia)
# But you can hardcode static mappings here too:
g, alice, group:admin

4. The Go Middleware logic
Your agent should implement a middleware that extracts the Remote-Groups header (sent by Authelia) and feeds it to Casbin.
func AuthzMiddleware(e *casbin.Enforcer) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // 1. Get User and Groups from Authelia headers
            user := r.Header.Get("Remote-User")
            groupsStr := r.Header.Get("Remote-Groups") // e.g., "admin,dev"
            groups := strings.Split(groupsStr, ",")

            obj := r.URL.Path
            act := r.Method

            // 2. Check each group the user belongs to
            authorized := false
            for _, group := range groups {
                // Prepend 'group:' to match our policy.csv format
                if ok, _ := e.Enforce("group:"+group, obj, act); ok {
                    authorized = true
                    break
                }
            }

            // 3. Fallback: Check the individual username too
            if !authorized {
                authorized, _ = e.Enforce(user, obj, act)
            }

            if !authorized {
                http.Error(w, "Forbidden by Casbin Policy", http.StatusForbidden)
                return
            }

            next.ServeHTTP(w, r)
        })
    }
}

5. Summary Checklist for the Agent
To get this running today, the agent must:
 * Configure Authelia to protect the domain (e.g., app.example.com).
 * Enable Header Injection in the reverse proxy so Remote-Groups reaches the Go app.
 * Initialize Casbin in the Go app using casbin.NewEnforcer("model.conf", "policy.csv").
 * Wrap the Router with the middleware provided above.
Would you like me to generate a full docker-compose file that spins up Authelia, Redis, and a sample Go app all at once?

