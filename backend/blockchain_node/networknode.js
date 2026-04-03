const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const Blockchain = require('./blockchain');
const rp = require('request-promise');
const cors = require('cors');

const bitcoin = new Blockchain();
const port = process.argv[2];

app.use(bodyParser.json());
app.use(cors());

// Get full blockchain
app.get('/blockchain', (req, res) => res.send(bitcoin));

// Add transaction (Patient Record Access)
app.post('/transaction', (req, res) => {
    const blockIndex = bitcoin.addTransactionToPendingTransactions(req.body);
    res.json({ note: `Record will be added in block ${blockIndex}.` });
});

// Mine a block to secure the records
app.get('/mine', (req, res) => {
    const lastBlock = bitcoin.getLastBlock();
    const previousBlockHash = lastBlock['hash'];
    const currentBlockData = {
        transactions: bitcoin.pendingTransactions,
        index: lastBlock['index'] + 1,
    };
    const nonce = bitcoin.proofOfWork(previousBlockHash, currentBlockData);
    const blockHash = bitcoin.hashBlock(previousBlockHash, currentBlockData, nonce);
    const newBlock = bitcoin.createNewBlock(nonce, previousBlockHash, blockHash);

    res.json({ note: "New medical record block mined successfully", block: newBlock });
});

app.listen(port, () => console.log(`Blockchain Node running on port ${port}...`));