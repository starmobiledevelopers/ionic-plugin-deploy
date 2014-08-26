var IonicUpdate = {
    initialize: function(app_id, success, failure) {
      cordova.exec(
        success,
        failure,
        'IonicUpdate',
        'initialize',
        [app_id]
      );
    },
    check: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'IonicUpdate',
            'check',
            []
        );
    },
    download: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicUpdate',
    		'download',
    		[]
    	);
    },
    extract: function(success,failure) {
      cordova.exec(
        success,
        failure,
        'IonicUpdate',
        'extract',
        []
      );
    },
    redirect: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicUpdate',
    		'redirect',
    		[]
    	);
    }
}

module.exports = IonicUpdate;