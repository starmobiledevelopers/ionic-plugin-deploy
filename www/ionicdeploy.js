var IonicDeploy = {
    initialize: function(app_id, success, failure) {
      cordova.exec(
        success,
        failure,
        'IonicDeploy',
        'initialize',
        [app_id]
      );
    },
    check: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'IonicDeploy',
            'check',
            []
        );
    },
    download: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicDeploy',
    		'download',
    		[]
    	);
    },
    extract: function(success,failure) {
      cordova.exec(
        success,
        failure,
        'IonicDeploy',
        'extract',
        []
      );
    },
    redirect: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicDeploy',
    		'redirect',
    		[]
    	);
    }
}

module.exports = IonicDeploy;
