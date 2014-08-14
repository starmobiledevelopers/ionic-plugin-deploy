var updatePlugin = {
    checkForUpdates: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'UpdatePlugin',
            'checkForUpdates',
            []
        );
    },
    download: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'UpdatePlugin',
    		'download',
    		[]
    	);
    },
    redirect: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'UpdatePlugin',
    		'redirect',
    		[]
    	);
    },
    read: function(success, failure) {
    	cordova.exec(
    		success,
    		failure,
    		'UpdatePlugin',
    		'read',
    		[]
    	);
    }
}