import axios from "axios";

function App({ keycloak }) {

    const callProducts = async () => {
        await keycloak.updateToken(30); // refresh token si besoin

        const response = await axios.get(
            "http://localhost:8085/products",
            {
                headers: {
                    Authorization: `Bearer ${keycloak.token}`,
                },
            }
        );

        alert(response.data);
    };

    const callOrders = async () => {
        await keycloak.updateToken(30);

        const response = await axios.post(
            "http://localhost:8085/orders",
            {},
            {
                headers: {
                    Authorization: `Bearer ${keycloak.token}`,
                },
            }
        );

        alert(response.data);
    };

    const copyToken = async () => {
        await keycloak.updateToken(30);
        navigator.clipboard.writeText(keycloak.token);
        alert("Token copié dans le presse-papier !");
    };

    const showTokenInfo = () => {
        console.log("=== TOKEN INFO ===");
        console.log("Token:", keycloak.token);
        console.log("Username:", keycloak.tokenParsed.preferred_username);
        console.log("Email:", keycloak.tokenParsed.email);
        console.log("Rôles:", keycloak.tokenParsed.realm_access.roles);
        console.log("Expire dans:", Math.floor((keycloak.tokenParsed.exp * 1000 - Date.now()) / 1000), "secondes");
        alert("Token info affiché dans la console (F12)");
    };

    return (
        <div style={{ padding: "30px", fontFamily: "Arial" }}>
            <h2>React + Keycloak + API Gateway</h2>

            <p>
                 Utilisateur : <b>{keycloak.idTokenParsed?.preferred_username}</b>
            </p>
            <p>
                Email : <b>{keycloak.idTokenParsed?.email}</b>
            </p>
            <p>
                 Rôles :
                <b> {keycloak.tokenParsed?.realm_access?.roles.join(", ")}</b>
            </p>

            <button onClick={callProducts}>
                Voir Produits
            </button>

            <button onClick={callOrders} style={{ marginLeft: "10px" }}>
                Créer Commande
            </button>

            <br /><br />

            <button onClick={copyToken} style={{ backgroundColor: "#4CAF50", color: "white" }}>
                📋 Copier Token
            </button>

            <button onClick={showTokenInfo} style={{ marginLeft: "10px", backgroundColor: "#2196F3", color: "white" }}>
                ℹ️ Voir Token Info
            </button>

            <br /><br />

            <button onClick={() => keycloak.logout()}>
                Se déconnecter
            </button>
        </div>
    );
}

export default App;
