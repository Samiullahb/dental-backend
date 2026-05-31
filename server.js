app.post("/api/vapi/webhook", (req, res) => {
  const event = req.body;

  console.log("Vapi Event Received:", event);

  // Example: handle tool call (appointment booking)
  if (event.type === "tool-calls") {
    const toolData = event.data;

    console.log("Tool Call Data:", toolData);

    // Example response
    return res.json({
      success: true,
      message: "Tool call processed successfully"
    });
  }

  res.json({ success: true });
});
