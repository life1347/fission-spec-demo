const momentpackage = require('moment')

module.exports = async function(context) {

    return {
        status: 200,
        body: momentpackage().format()
    };
}  