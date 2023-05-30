"use strict";
const { exec } = require('child_process');
const glob = require("glob");


if (process.argv) {
    const filename = process.argv.find((arg) => arg.includes('--flatten=')).split('--flatten=').pop() + '.sol';
    const file = `.//contracts/${filename}`
    const outputFileName = "./flattened/" + filename;
    const command = "npx truffle-flattener " + file + " --output " + outputFileName;
    exec(command, (err, stdout, stderr) => {
        if (err) {
            throw err;
        } else if (stderr) {
            throw stderr;
        }
    });
} else {
    glob.sync("./contracts/*/*.sol").forEach(file => {
        const outputFileName = "./flattened/" + file.substr(file.lastIndexOf("/") + 1);
        const command = "npx truffle-flattener " + file + " --output " + outputFileName;
        exec(command, (err, stdout, stderr) => {
            if (err) {
                throw err;
            } else if (stderr) {
                throw stderr;
            }
        });

    });

    glob.sync("./contracts/*/*/*.sol").forEach(file => {
        const outputFileName = "./flattened/" + file.substr(file.lastIndexOf("/") + 1);
        const command = "npx truffle-flattener " + file + " --output " + outputFileName;
        exec(command, (err, stdout, stderr) => {
            if (err) {
                throw err;
            } else if (stderr) {
                throw stderr;
            }
        });

    });

    glob.sync("./contracts/*.sol").forEach(file => {
        const outputFileName = "./flattened/" + file.substr(file.lastIndexOf("/") + 1);
        const command = "npx truffle-flattener " + file + " --output " + outputFileName;
        exec(command, (err, stdout, stderr) => {
            if (err) {
                throw err;
            } else if (stderr) {
                throw stderr;
            }
        });

    });
}