var IonicUpdate = {
    checkForUpdates: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'IonicUpdate',
            'checkForUpdates',
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