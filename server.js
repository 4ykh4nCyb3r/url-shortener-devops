const express = require("express");
const mongoose = require("mongoose"); //interact with MongoDB database
const shortid = require("shortid");
const path = require("path");
const Url = require("./models/Url");

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public"))); // serve frontend

// Connect to MongoDB
mongoose.connect("mongodb://mongo:27017/urlshortener", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
// changee
// POST /shorten - create short URL
app.post("/shorten", async (req, res) => {
  const { originalUrl } = req.body;
  if (!originalUrl) return res.status(400).json({ error: "URL is required" });

  const shortUrl = shortid.generate();

  const newUrl = new Url({ originalUrl, shortUrl });
  await newUrl.save();

  res.json({ shortUrl: `/${shortUrl}` }); // frontend will handle base URL
});

// GET /:shortUrl - redirect to original URL
app.get("/:shortUrl", async (req, res) => {
  const { shortUrl } = req.params;
  const url = await Url.findOne({ shortUrl });

  if (!url) return res.status(404).send("URL not found");

  res.redirect(url.originalUrl);
});

app.listen(3000, () => console.log("🚀 Server running on port 3000"));
