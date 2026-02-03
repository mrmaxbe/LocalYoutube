package com.example.login;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLDecoder;
import java.util.Arrays;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class DisplayFileServlet extends HttpServlet {
    
	private String getFfmpegPath() {
	    String[] paths = {
	        "/opt/homebrew/bin/ffmpeg", 
	        "/usr/local/bin/ffmpeg", 
	        "/usr/bin/ffmpeg"
	    };

	    for (String path : paths) {
	        File f = new File(path);
	        if (f.exists() && f.canExecute()) {
	            return path; 
	        }
	    }
	    return "/opt/homebrew/bin/ffmpeg"; 
	}

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String filePath = request.getParameter("path");
        String type = request.getParameter("type"); 
        if (filePath == null) return;

        filePath = URLDecoder.decode(filePath, "UTF-8");
        File file = new File(filePath);

        if (!file.exists()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String etag = "W/\"" + file.length() + "-" + file.lastModified() + "\"";
        if (etag.equals(request.getHeader("If-None-Match"))) {
            response.setStatus(HttpServletResponse.SC_NOT_MODIFIED);
            return;
        }
        response.setHeader("ETag", etag);
        response.setHeader("Cache-Control", "public, max-age=86400");

        if ("thumb".equals(type)) {
            handleThumbnailRequest(file, response);
            return;
        } else if ("waveform".equals(type)) {
            handleWaveformRequest(file, response);
            return;
        }

        String name = file.getName().toLowerCase();
        String contentType = getServletContext().getMimeType(name);
        if (name.endsWith(".mp3")) contentType = "audio/mpeg";
        else if (name.endsWith(".mov")) contentType = "video/quicktime";
        else if (name.endsWith(".mp4")) contentType = "video/mp4";
        else if (name.endsWith(".mpg") || name.endsWith(".mpeg")) contentType = "video/mpeg";

        if (request.getHeader("Range") != null) {
            handleRangeRequest(file, request.getHeader("Range"), contentType, response);
        } else {
            response.setContentType(contentType);
            response.setContentLengthLong(file.length());
            streamFile(file, response.getOutputStream());
        }
    }

    private void handleWaveformRequest(File mp3File, HttpServletResponse response) throws IOException {
        String tmpDir = System.getProperty("java.io.tmpdir");
        String waveName = "wave_" + Math.abs(mp3File.getAbsolutePath().hashCode()) + ".png";
        File cacheFile = new File(tmpDir, waveName);

        if (!cacheFile.exists()) {
            try {
                ProcessBuilder pb = new ProcessBuilder(
                    getFfmpegPath(), "-i", mp3File.getAbsolutePath(),
                    "-filter_complex", "showwavespic=s=640x240:colors=white", 
                    "-frames:v", "1", "-y", cacheFile.getAbsolutePath()
                );
                pb.redirectErrorStream(true);
                pb.start().waitFor();
            } catch (Exception e) { e.printStackTrace(); }
        }

        if (cacheFile.exists()) {
            response.setContentType("image/png");
            streamFile(cacheFile, response.getOutputStream());
        }
    }

    private void handleThumbnailRequest(File videoFile, HttpServletResponse response) throws IOException {
        String tmpDir = System.getProperty("java.io.tmpdir");
        String thumbName = "thumb_" + Math.abs(videoFile.getAbsolutePath().hashCode()) + ".jpg";
        File cacheFile = new File(tmpDir, thumbName);

        if (!cacheFile.exists()) {
            
        	try {
        	    ProcessBuilder pb = new ProcessBuilder(
        	        getFfmpegPath(), "-ss", "00:00:05", "-i", videoFile.getAbsolutePath(),
        	        "-vframes", "1", "-q:v", "2", "-y", cacheFile.getAbsolutePath()
        	    );
        	    pb.redirectErrorStream(true);
        	    Process p = pb.start();
        	    
        	    // Read the output to see the error message from FFmpeg
        	    java.util.Scanner s = new java.util.Scanner(p.getInputStream());
        	    while (s.hasNextLine()) {
        	        System.out.println("FFMPEG LOG: " + s.nextLine());
        	    }
        	    
        	    int exitCode = p.waitFor();
        	    System.out.println("FFMPEG Exit Code: " + exitCode);
        	} catch (Exception e) { 
        	    e.printStackTrace(); 
        	}
        }

        if (cacheFile.exists()) {
            response.setContentType("image/jpeg");
            streamFile(cacheFile, response.getOutputStream());
        }
    }

    private void streamFile(File file, OutputStream os) throws IOException {
        try (FileInputStream is = new FileInputStream(file)) {
            byte[] buffer = new byte[65536];
            int read;
            while ((read = is.read(buffer)) != -1) os.write(buffer, 0, read);
        }
    }

    private void handleRangeRequest(File file, String range, String contentType, HttpServletResponse response) throws IOException {
        long length = file.length();
        String[] ranges = range.replace("bytes=", "").split("-");
        long start = Long.parseLong(ranges[0]);
        long end = ranges.length > 1 ? Long.parseLong(ranges[1]) : length - 1;

        response.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
        response.setContentType(contentType);
        response.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + length);
        response.setContentLengthLong(end - start + 1);

        try (java.io.RandomAccessFile raf = new java.io.RandomAccessFile(file, "r");
             OutputStream os = response.getOutputStream()) {
            raf.seek(start);
            byte[] buffer = new byte[65536];
            long toRead = end - start + 1;
            while (toRead > 0) {
                int len = (int) Math.min(buffer.length, toRead);
                int read = raf.read(buffer, 0, len);
                if (read == -1) break;
                os.write(buffer, 0, read);
                toRead -= read;
            }
        }
    }
}
