const express=require("express");
const app=express();
const PORT=process.env.PORT||5000;
app.get("/",(req,res)=>res.send("✅ Backend API is running successfully!"));
app.listen(PORT,()=>console.log(`Backend on ${PORT}`));
