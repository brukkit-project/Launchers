package net.launcher.components;

import java.awt.Color;
import java.awt.Cursor;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

import javax.swing.ButtonModel;
import javax.swing.JButton;

import net.launcher.run.Settings;

public class Dragbutton extends JButton
{
	private static final long serialVersionUID = 1L;

	public BufferedImage img1 = (BufferedImage) createImage(1, 1);
	public BufferedImage img2 = (BufferedImage) createImage(1, 1);
	public BufferedImage img3 = (BufferedImage) createImage(1, 1);
	
	public Dragbutton()
	{
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
		if(buttonModel.isRollover())
		{
			if(buttonModel.isPressed())
			{
				g.drawImage(img3, 0, 0, getWidth(), getHeight(), null);
			}
			else g.drawImage(img2, 0, 0, getWidth(), getHeight(), null);
		} else g.drawImage(img1, 0, 0, getWidth(), getHeight(), null);
		if(Settings.drawTracers)
		{
			g.setColor(Color.CYAN);
			g.drawRect(0, 0, getWidth() - 1, getHeight() - 1);
		}
		g.dispose();
		super.paintComponent(maing);
	}
}