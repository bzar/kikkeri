if process.env.CONFIG_FILE
  module.exports = require process.env.CONFIG_FILE
else
  module.exports =
    path: ''
    slack:
      incomingWebHookUrl: ''
      channelTags:
        * tags: []
          channel: ''
        ...
