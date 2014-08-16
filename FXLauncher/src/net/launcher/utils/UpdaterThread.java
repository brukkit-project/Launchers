package net.launcher.utils;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.URL;
//import java.net.URLConnection;
import java.security.MessageDigest;
import java.util.List;

import net.launcher.components.Game;


public class UpdaterThread extends Thread
{
	public int procents = 0;
	public long totalsize = 0;
	public long currentsize = 0;
	public String currentfile = "...";
	public int downloadspeed = 0;
	public List<String> files;
	public String state = "...";
	public boolean error = false;
	public boolean zipupdate = false;
	public boolean asupdate = false;
	public String answer;
	
	public UpdaterThread(List<String> files, boolean zipupdate, boolean asupdate,  String answer)
	{
		this.files = files;
		this.zipupdate = zipupdate;
		this.asupdate  = asupdate;
		this.answer = answer;
	}
	
	public void run()
	{ try {
		String pathTo = BaseUtils.getAssetsDir().getAbsolutePath();
		String urlTo = BaseUtils.buildUrl("clients");
		File dir = new File(pathTo);
        if (!dir.exists()) dir.mkdirs();
		
		totalsize = GuardUtils.filesize;
		
		state = "Baixando arquivos...";
		
		byte[] buffer = new byte[65536];
		for (int i = 0; i < files.size(); i++)
		{
			currentfile = files.get(i);
			String file = currentfile.replace(" ", "%20");
			BaseUtils.send("Downloading file: " + currentfile);
			try {
              dir = new File(pathTo + "/" + currentfile.substring(0, currentfile.lastIndexOf("/")));
			} catch (Exception e) {
			}
			if (!dir.exists()) dir.mkdirs();
			InputStream is = new BufferedInputStream(new URL(urlTo + file).openStream());
			FileOutputStream fos = new FileOutputStream(pathTo + "/" + currentfile);
			long downloadStartTime = System.currentTimeMillis();
			int downloadedAmount = 0, bs = 0;
			MessageDigest m = MessageDigest.getInstance("MD5");
			while((bs = is.read(buffer, 0, buffer.length)) != -1)
			{
				fos.write(buffer, 0, bs);
				m.update(buffer, 0, bs);
				currentsize += bs;
				procents = (int)(currentsize * 100 / totalsize);
				downloadedAmount += bs;
				long timeLapse = System.currentTimeMillis() - downloadStartTime;
				if (timeLapse >= 1000L)
				{
					downloadspeed = (int)((int) (downloadedAmount / (float) timeLapse * 100.0F) / 100.0F);
					downloadedAmount = 0;
					downloadStartTime += 1000L;
				}
			}
			is.close();
			fos.close();
			BaseUtils.send("File downloaded: " + currentfile);
		}
		state = "Download concluído";
		
		if(zipupdate)
		{
			String path = BaseUtils.getMcDir().getAbsolutePath() + File.separator;
			String file = path + "config.zip";
			BaseUtils.setProperty(BaseUtils.getClientName() + "_zipmd5", GuardUtils.hash(new File(file).toURI().toURL()));
			ZipUtils.unzip(path, file);
		}
		
		if(asupdate)
		{
			String path = BaseUtils.getAssetsDir().getAbsolutePath() + File.separator;
			String file = path + "assets.zip";
			BaseUtils.setProperty("assets_aspmd5", GuardUtils.hash(new File(file).toURI().toURL()));
			ZipUtils.unzip(path, file);
		}
		
		new Game(answer);
	} catch (Exception e) { e.printStackTrace(); state = e.toString(); error = true; }}
}
