package archie

import java.time.format.DateTimeFormatter

import groovy.json.*
import java.nio.file.Files
import java.nio.file.Paths


class Utils {

    static final DateTimeFormatter DTF = DateTimeFormatter.ISO_OFFSET_DATE_TIME

    static def sendMessage(def msgContentData) {
        String authMode = System.getenv('ARCHIE_AMQ_AUTH_MODE')
        String clientId = System.getenv('ARCHIE_OIDC_NATIVE_CLIENT_ID')
        String queueMode = System.getenv('ARCHIE_AMQ_QUEUE_MODE')

        def amqConfig = [
            type: 'activemq',
            queue: 'analysis_updated',
            brokerURL: System.getenv('ARCHIE_AMQ_URL'),
            events: '',
            username: System.getenv('ARCHIE_AMQ_USERNAME'),
            password: System.getenv('ARCHIE_AMQ_PASSWORD'),
        ]

        if (authMode == 'OIDC' && clientId) {
            String token
            if (System.getenv('ARCHIE_API_IDTOKEN')) {
                token = System.getenv('ARCHIE_API_IDTOKEN')
            }
            else {
                def oidcInfo = getOIDCInfo(clientId)
                token = oidcInfo.id_token
            }
            amqConfig['username'] = clientId
            amqConfig['password'] = token
            def headers = [
                'user': queueMode == 'USER' ? System.getProperty('user.name') : 'anonymous',
                'Authorization': "Bearer ${token}"
            ]
            sendAMQMessage(amqConfig, msgContentData, headers)
        }
        else {
            sendAMQMessage(amqConfig, msgContentData)
        }
    }

    static def getOIDCInfo(String clientId) {
        def archieConfDir = System.getenv('ARCHIE_CONF') ?: "~/.archie"
        def path = Paths.get(archieConfDir, "oidc.${clientId}.json").normalize()
        
        if(!Files.exists(path)) {
            throw new FileNotFoundException("The OIDC configuration file ${path} does not exist.")
        }
        
        def json = new JsonSlurper().parseText(path.toFile().text)

        if(!json.id_token) {
            throw new IllegalArgumentException("The OIDC configuration file ${path} does not contain an id_token.")
        }
        
        return json
    }

    static def sendAMQMessage(def amqConfig, def msgContentData, def headers = [:]) {
        def channel = new bpipe.notification.ActivemqNotificationChannel(amqConfig)

        try {
            def msg = channel.session.createTextMessage(JsonOutput.prettyPrint(JsonOutput.toJson(msgContentData)))
            if (!headers.empty) {
                headers.each { String k, String v -> msg.setStringProperty(k, v) }
            }
            println "Sending message to broker=${amqConfig.brokerURL}, queue=${amqConfig.queue}"
            channel.producer.send(channel.queue, msg)
        }
        catch (Exception e) {
            println "Unexpected exception thrown, ${e.message}, ${e.cause}"
        }
        finally {
            channel.close()
        }
    }
}
