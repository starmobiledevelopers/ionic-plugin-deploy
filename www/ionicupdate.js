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
    redirect: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicUpdate',
    		'redirect',
    		[]
    	);
    },
    read: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'IonicUpdate',
    		'read',
    		[]
    	);
    }
}

module.exports = IonicUpdate;