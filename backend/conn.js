const mongoose = require('mongoose')
// const URL = process.env.MONGO_URI
const URL = "mongodb://localhost:27017/TravelMemory"

mongoose.connect(URL)
mongoose.Promise = global.Promise

const db = mongoose.connection
db.on('error', console.error.bind(console, 'DB ERROR: '))

module.exports = {db, mongoose}