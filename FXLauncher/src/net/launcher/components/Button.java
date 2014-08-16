package net.launcher.components;

import java.awt.Color;
import java.awt.Cursor;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

import javax.swing.ButtonModel;
import javax.swing.JButton;

import net.launcher.MusPlay;
import net.launcher.run.Settings;
import static net.launcher.utils.ImageUtils.*;

public class Button extends JButton
{
	private static final long serialVersionUID = 1L;
	
	public BufferedImage defaultTX;
	public BufferedImage rolloverTX;
	public BufferedImage pressedTX;
	public BufferedImage lockedTX;
	
	public Button(String text)
	{
		setText(text);
		setBorderPainted(false);
		setContentAreaFilled(false);
		setFocusPainted(false);
		setOpaque(false);
		setFocusable(false);
		setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
	}

	protected void paintComponent(Graphics maing)
	{
		ButtonModel buttonModel = getModel();
		Graphics2D g = (Graphics2D) maing.create();
		g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
		
		int w = getWidth();
		int h = getHeight();
		
		if(!isEnabled())
		{
			g.drawImage(genButton(w, h, lockedTX), 0, 0, w, h, null);
		} else if(buttonModel.isRollover())
		{
			if(buttonModel.isPressed())
			{
				new MusPlay("click.mp3");
				g.drawImage(genButton(w, h, pressedTX), 0, 0, w, h, null);
			} else g.drawImage(genButton(w, h, rolloverTX), 0, 0, w, h, null);
		} else g.drawImage(genButton(w, h, defaultTX), 0, 0, w, h, null);
		
		if(Settings.drawTracers)
		{
			g.setColor(Color.RED);
			g.drawRect(0, 0, w - 1, h - 1);
		}
		g.dispose();
		super.paintComponent(maing);
	}
}