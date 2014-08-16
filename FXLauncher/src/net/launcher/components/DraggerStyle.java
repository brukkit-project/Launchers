package net.launcher.components;

import java.awt.Color;

import javax.swing.SwingConstants;

import net.launcher.utils.BaseUtils;

public class DraggerStyle
{
	public int x = 0;
	public int y = 0;
	public int w = 0;
	public int h = 0;
	public String fontName= BaseUtils.empty;
	public float fontSize = 1F;
	public Color color;
	public Align align;
	
	public DraggerStyle(int x, int y, int w, int h, String fontName, float fontSize, Color color, Align align)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.fontName = fontName;
		this.fontSize = fontSize;
		this.color = color;
		this.align = align;
	}
	
	public void apply(Dragger dragger)
	{
		dragger.title.setHorizontalAlignment(align == Align.LEFT ? SwingConstants.LEFT : align == Align.CENTER ? SwingConstants.CENTER : SwingConstants.RIGHT);
		dragger.title.setFont(BaseUtils.getFont(fontName, fontSize));
		dragger.title.setForeground(color);
		
		dragger.setBounds(x, y, w, h);
	}
}