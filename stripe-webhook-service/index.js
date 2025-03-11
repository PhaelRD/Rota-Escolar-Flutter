require("dotenv").config();
const express = require("express");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const admin = require("firebase-admin");

// Inicializar o Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://rota-escolar-7c046-default-rtdb.firebaseio.com", // Substitua pelo URL do seu banco de dados
});

const app = express();

// Middleware para validar Webhook do Stripe
app.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    const sig = req.headers["stripe-signature"];

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      console.error("⚠️  Webhook error:", err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Manipular diferentes tipos de eventos
    switch (event.type) {
      case "checkout.session.completed": {
        const checkoutSessionCompleted = event.data.object;

        // Verificar se o pagamento foi bem-sucedido
        if (checkoutSessionCompleted.payment_status === "paid") {
          const clientReferenceId = checkoutSessionCompleted.client_reference_id;
          const customerId = checkoutSessionCompleted.customer;
          const subscriptionId = checkoutSessionCompleted.subscription; // Obtendo o Subscription ID

          // Atualizar o Firebase com as informações
          try {
            const userRef = admin.database().ref(`users/${clientReferenceId}`);
            await userRef.update({
              "userInfos/plano": 1,
              "stripe/customerId": customerId,
              "stripe/subscriptionId": subscriptionId,
            });

            console.log(`Plano do usuário ${clientReferenceId} atualizado para 1.`);
            console.log(`Subscription ID salvo: ${subscriptionId}`);
          } catch (error) {
            console.error("Erro ao atualizar o Firebase:", error.message);
            return res.status(500).send("Erro ao atualizar o Firebase.");
          }
        } else {
          console.log("Pagamento não concluído.");
        }
        break;
      }

      case "customer.subscription.deleted": {
        // Este evento é acionado quando uma assinatura é cancelada ou expirada.
        const subscription = event.data.object;
        const customerId = subscription.customer;

        try {
          // Buscar o(s) usuário(s) no Firebase cujo stripe/customerId corresponda ao customerId recebido
          const usersRef = admin.database().ref('users');
          const snapshot = await usersRef.orderByChild('stripe/customerId').equalTo(customerId).once('value');

          if (snapshot.exists()) {
            snapshot.forEach(childSnapshot => {
              childSnapshot.ref.update({
                "userInfos/plano": 0,
              });
              console.log(`Plano atualizado para 0 para o usuário ${childSnapshot.key}.`);
            });
          } else {
            console.log(`Nenhum usuário encontrado para o customerId ${customerId}.`);
          }
        } catch (error) {
          console.error("Erro ao atualizar o Firebase:", error.message);
          return res.status(500).send("Erro ao atualizar o Firebase.");
        }
        break;
      }

      // ... Handle other event types
      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  }
);

// Iniciar servidor
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
});
