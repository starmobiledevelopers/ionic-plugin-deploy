package com.ionic.update;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class UpdatePlugin extends CordovaPlugin {
    Context myContext = null;

    /**
     * Sets the context of the Command. This can then be used to do things like
     * get file paths associated with the Activity.
     *
     * @param cordova The context of the main Activity.
     * @param webView The CordovaWebView Cordova is running in.
     */
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        this.myContext = this.cordova.getActivity().getApplicationContext();
        /*boolean updatesAvailable = checkForUpdates();

        // If there are no updates available, check to see if any updates have been downloaded
        // and redirect to the updated version
        if (!updatesAvailable) {
            webView.loadUrlIntoView("http://android.com/");
        }*/
    }

    /**
     * Executes the request and returns PluginResult.
     *
     * @param action            The action to execute.
     * @param args              JSONArry of arguments for the plugin.
     * @param callbackContext   The callback id used when calling back into JavaScript.
     * @return                  True if the action was valid, false if not.
     */
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("checkForUpdates")) {
            //Boolean result = checkForUpdates();

            /*String FILENAME = "hello_file";
            String string = "hello world!";

            try {
                FileOutputStream fos = this.myContext.openFileOutput(FILENAME, Context.MODE_PRIVATE);
                fos.write(string.getBytes());
                fos.close();
            } catch (FileNotFoundException e) {
                //TODO
            } catch (IOException e) {
                //TODO
            }*/

            //downloadUpdate(callbackContext);

            //unzip("www.zip", Environment.getExternalStorageDirectory() + "/unzipped/");

            this.checkForUpdates(callbackContext);
            return true;
        } else if (action.equals("download")) {
            this.downloadUpdate(callbackContext);
            return true;
        } else if (action.equals("redirect")) {
            // In here I want to change unzipped to be the uuid of the current version as defined
            // in local storage
            SharedPreferences prefs = getPreferences();

            String uuid = prefs.getString("uuid", "");
            //webView.loadUrlIntoView("file://" + Environment.getExternalStorageDirectory() + "/" + uuid + "/index.html");
            File versionDir = this.myContext.getDir(uuid, Context.MODE_PRIVATE);
            Log.i("REDIRECT_1", versionDir.getAbsolutePath().toString() + "index.html");
            Log.i("REDIRECT", versionDir.toURI() + "index.html");
            webView.loadUrlIntoView(versionDir.toURI() + "index.html");
            return true;
        } else if (action.equals("read")) {
            String file_contents = "";

            try {
                FileInputStream in = this.myContext.openFileInput("hello_file");
                InputStreamReader inputStreamReader = new InputStreamReader(in);
                BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = bufferedReader.readLine()) != null) {
                    sb.append(line);
                }
                inputStreamReader.close();

                file_contents = sb.toString();
            } catch (FileNotFoundException e) {
                //TODO
            } catch (IOException e) {
                //TODO
            }

            callbackContext.success(file_contents);
            return true;
        } else {
            return false;
        }
    }

    private void checkForUpdates(CallbackContext callbackContext) {
        String endpoint = "/api/v1/app/3ccaa3e3/updates/check";

        // Request shared preferences for this app id
        // Also, is there a way to pull the package name and fill it in on build?
        SharedPreferences prefs = getPreferences();

        String our_version = prefs.getString("uuid", "");

        try {
            JSONObject json = httpRequest(endpoint);

            if (json != null) {
                String deployed_version = json.getString("uuid");

                prefs.edit().putString("upstream_uuid", deployed_version).apply();

                Boolean updatesAvailable = !deployed_version.equals(our_version);

                callbackContext.success(updatesAvailable.toString());
            }
        } catch (JSONException e) {
            //TODO Handle problems..
        }

        callbackContext.error("Unable to contact update server");

    }

    private void downloadUpdate(CallbackContext callbackContext) {
        String endpoint = "/api/v1/app/3ccaa3e3/updates/download";

        try {
            JSONObject json = httpRequest(endpoint);

            if (json != null) {
                String url = json.getString("download_url");

                final DownloadTask downloadTask = new DownloadTask(this.myContext, callbackContext);

                downloadTask.execute(url);
            }
        } catch (JSONException e) {
            //TODO Handle problems..
        }
    }

    private JSONObject httpRequest(String endpoint) {
        HttpURLConnection urlConnection = null;

        try {
            String server = "http://7b5ed69d.ngrok.com";


            URL url = new URL(server + endpoint);
            urlConnection = (HttpURLConnection) url.openConnection();

            InputStream in = new BufferedInputStream(urlConnection.getInputStream());
            String result = readStream(in);

            JSONObject json = new JSONObject(result);

            return json;
        } catch (JSONException e) {
            //TODO Handle problems..
        } catch (MalformedURLException e) {
            //TODO Handle problems..
        } catch (IOException e) {
            //TODO Handle problems..
        } finally {
            urlConnection.disconnect();
        }

        return null;
    }

    private SharedPreferences getPreferences() {
        // Request shared preferences for this app id
        SharedPreferences prefs = this.myContext.getSharedPreferences(
                "com.ionic.3ccaa3e3", Context.MODE_PRIVATE
        );

        return prefs;
    }

    /**
     * This shouldn't be required anymore...
     *
     * @param is
     * @return
     */
    private String readStream(InputStream is) {
        try {
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            int i = is.read();
            while(i != -1) {
                bo.write(i);
                i = is.read();
            }
            return bo.toString();
        } catch (IOException e) {
            return "";
        }
    }

    private class DownloadTask extends AsyncTask<String, Integer, String> {
        private Context myContext;
        private CallbackContext callbackContext;

        public DownloadTask(Context context, CallbackContext callbackContext) {
            this.myContext = context;
            this.callbackContext = callbackContext;
        }

        public void unzip(String zip, String location) {
            try  {
                FileInputStream inputStream = this.myContext.openFileInput(zip);
                //FileInputStream inputStream = new FileInputStream(zip);
                ZipInputStream zipInputStream = new ZipInputStream(inputStream);
                ZipEntry zipEntry = null;

                // Get the full path to the internal storage
                String filesDir = this.myContext.getFilesDir().toString();

                // Make the version directory in internal storage
                File versionDir = this.myContext.getDir(location, Context.MODE_PRIVATE);

                Log.i("UNZIP_DIR", versionDir.getAbsolutePath().toString());

                while ((zipEntry = zipInputStream.getNextEntry()) != null) {
                    /*File file = new File(location + zipEntry.getName());
                    Log.i("UNZIP_STEP", "File Location: " + file);
                    file.getParentFile().mkdirs();*/

                    File newFile = new File(versionDir + "/" + zipEntry.getName());
                    newFile.getParentFile().mkdirs();

                    //FileOutputStream fileOutputStream = new FileOutputStream(location + zipEntry.getName());
                    FileOutputStream fileOutputStream = new FileOutputStream(newFile);
                    for (int bits = zipInputStream.read(); bits != -1; bits = zipInputStream.read()) {
                        fileOutputStream.write(bits);
                    }

                    zipInputStream.closeEntry();
                    fileOutputStream.close();

                }
                zipInputStream.close();
            } catch(Exception e) {
                //TODO Handle problems..
                Log.i("UNZIP_STEP", "Exception: " + e.getMessage());
            }

        }

        @Override
        protected String doInBackground(String... sUrl) {
            InputStream input = null;
            FileOutputStream output = null;
            HttpURLConnection connection = null;
            try {
                URL url = new URL(sUrl[0]);
                connection = (HttpURLConnection) url.openConnection();
                connection.connect();

                // expect HTTP 200 OK, so we don't mistakenly save error report
                // instead of the file
                if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                    return "Server returned HTTP " + connection.getResponseCode()
                            + " " + connection.getResponseMessage();
                }

                // this will be useful to display download percentage
                // might be -1: server did not report the length
                int fileLength = connection.getContentLength();

                // download the file
                input = connection.getInputStream();
                output = this.myContext.openFileOutput("www.zip", Context.MODE_PRIVATE);
                /*fos.write(string.getBytes());
                fos.close();
                output = new FileOutputStream("/sdcard/file_name.extension");*/
                //output = new FileOutputStream(Environment.getExternalStorageDirectory() + "/www.zip");

                byte data[] = new byte[4096];
                long total = 0;
                int count;
                while ((count = input.read(data)) != -1) {
                    /*// allow canceling with back button
                    if (isCancelled()) {
                        input.close();
                        return null;
                    }*/
                    total += count;

                    output.write(data, 0, count);

                    // Send the current download progress to a callback
                    if (fileLength > 0) {
                        int progress = (int) (total * 100 / fileLength);
                        android.util.Log.i("DOWNLOAD_PROGRESS", Integer.toString(progress));
                        /*PluginResult progressResult = new PluginResult(PluginResult.Status.OK, (int) (total * 100 / fileLength));
                        progressResult.setKeepCallback(true);
                        callbackContext.sendPluginResult(progressResult);*/
                    }
                }
            } catch (Exception e) {
                callbackContext.error("Something failed with the download...");
                return e.toString();
            } finally {
                try {
                    if (output != null)
                        output.close();
                    if (input != null)
                        input.close();
                } catch (IOException ignored) {
                }

                if (connection != null)
                    connection.disconnect();
            }

            // Request shared preferences for this app id
            SharedPreferences prefs = getPreferences();

            // Set the saved uuid to the most recently acquired upstream_uuid
            String uuid = prefs.getString("upstream_uuid", "");

            //this.unzip(Environment.getExternalStorageDirectory() + "/www.zip", Environment.getExternalStorageDirectory() + "/" + uuid + "/");

            this.unzip("www.zip", uuid);

            prefs.edit().putString("uuid", uuid).apply();

            callbackContext.success("Zip file download complete");
            return null;
        }
    }
}
