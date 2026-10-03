"""Render the canonical Chinese PRD to an inspectable, typeset A4 PDF."""
import argparse
import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, CondPageBreak, Table, TableStyle, Image

ROOT = Path(__file__).resolve().parents[2]
FOREST = colors.HexColor('#173B33')
INK = colors.HexColor('#203C34')
MUTED = colors.HexColor('#616E66')
LINE = colors.HexColor('#D9DED2')
PAPER = colors.HexColor('#F6F5EF')


def inline(value):
    # Escape first, then only introduce known ReportLab markup for Markdown links.
    value = html.escape(value, quote=False)
    value = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)', r'<link href="\2" color="#173B33"><u>\1</u></link>', value)
    return value.replace('`', '')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default=str(ROOT / 'output/pdf/Headly-PRD.pdf'))
    parser.add_argument('--screens', default=str(ROOT / 'Product/screens'))
    args = parser.parse_args()
    pdfmetrics.registerFont(TTFont('HeadlyCN', '/System/Library/Fonts/Supplemental/Arial Unicode.ttf'))
    pdfmetrics.registerFont(TTFont('HeadlySerif', '/System/Library/Fonts/Supplemental/Georgia.ttf'))
    styles = {
        'body': ParagraphStyle('body', fontName='HeadlyCN', fontSize=9.4, leading=16.2, textColor=INK, spaceAfter=10, wordWrap='CJK'),
        'h1': ParagraphStyle('h1', fontName='HeadlyCN', fontSize=23, leading=32, textColor=FOREST, spaceAfter=22, keepWithNext=True, wordWrap='CJK'),
        'h2': ParagraphStyle('h2', fontName='HeadlyCN', fontSize=12.2, leading=19, textColor=INK, spaceBefore=7, spaceAfter=10, keepWithNext=True, wordWrap='CJK'),
        'cell': ParagraphStyle('cell', fontName='HeadlyCN', fontSize=8.2, leading=13, textColor=INK, wordWrap='CJK'),
        'header': ParagraphStyle('header', fontName='HeadlyCN', fontSize=8.4, leading=13, textColor=colors.white, wordWrap='CJK'),
        'caption': ParagraphStyle('caption', fontName='HeadlyCN', fontSize=8, leading=13, textColor=MUTED, spaceAfter=9, wordWrap='CJK'),
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(str(output), pagesize=A4, rightMargin=49, leftMargin=49, topMargin=64, bottomMargin=56,
                            title='Headly 轻记产品需求文档', author='Headly', subject='简洁本地头痛记录 iOS 产品 PRD 1.0')
    story = []
    story += [Spacer(1, 52), Paragraph('Headly', ParagraphStyle('brand', fontName='HeadlySerif', fontSize=57, leading=68, textColor=FOREST)),
              Spacer(1, 24), Paragraph('轻记 头痛记录产品', ParagraphStyle('coverTitle', fontName='HeadlyCN', fontSize=25, leading=38, textColor=FOREST)),
              Paragraph('产品需求文档', ParagraphStyle('coverSubtitle', fontName='HeadlyCN', fontSize=17, leading=29, textColor=INK)),
              Spacer(1, 37), Paragraph('两个主页面，一个记录浮层。<br/>无需登录，记录保存在设备本地。', ParagraphStyle('coverBody', fontName='HeadlyCN', fontSize=13, leading=24, textColor=MUTED)),
              Spacer(1, 74), Paragraph('版本 1.0  ·  2026 年 10 月 3 日', styles['body']),
              Paragraph('面向产品评审与 iOS 开发', styles['caption']), Spacer(1, 14),
              Paragraph('范围包含用户场景、逐页交互、记录模型、状态校验、统计口径、隐私边界、视觉规范与验收条件。', styles['body']),
              PageBreak()]
    screens = Path(args.screens)
    if all((screens / name).exists() for name in ['today.png', 'review.png', 'record.png']):
        story += [Paragraph('核心界面', styles['h1']), Paragraph('今日负责记录当下，回顾负责查看历史，记录浮层只要求主动选择一个强度。辅助操作收进详情及隐私浮层。', styles['body']), Spacer(1, 14)]
        images = []
        for name in ['today.png', 'review.png', 'record.png']:
            path = str(screens / name)
            source_width, source_height = ImageReader(path).getSize()
            image = Image(path, width=152, height=source_height * 152 / source_width)
            images.append(image)
        visual = Table([images, [Paragraph(t, styles['caption']) for t in ['01 今日', '02 回顾', '03 记录浮层']]], colWidths=[165.75] * 3)
        visual.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),10),('TOPPADDING',(0,1),(-1,1),12)]))
        story += [visual, Spacer(1, 18), Paragraph('这些截图来自实际运行的产品原型。演示记录为虚构数据，正式首次使用为空状态。', styles['caption']), PageBreak()]
    text = (ROOT / 'Product/PRD.md').read_text()
    lines = text.splitlines()
    i = 0
    first_section = True
    while i < len(lines):
        line = lines[i].strip()
        if not line or line.startswith('# '):
            i += 1; continue
        if line.startswith('## '):
            if not first_section:
                story += [CondPageBreak(145), Spacer(1, 20)]
            first_section = False
            story.append(Paragraph(inline(line[3:]), styles['h1'])); i += 1; continue
        if first_section:
            # Intro and version already included in the cover.
            i += 1; continue
        if line.startswith('### '):
            story.append(Paragraph(inline(line[4:]), styles['h2'])); i += 1; continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', c) for c in cells): rows.append(cells)
                i += 1
            count = len(rows[0])
            if count == 3: ratios = [0.23, 0.22, 0.55]
            elif count == 4: ratios = [0.14, 0.18, 0.32, 0.36]
            else: ratios = [1 / count] * count
            if rows[0][0] in ['编号'] and count == 4: ratios = [.10, .10, .23, .57]
            if rows[0][0] == '编号' and count == 3: ratios = [.11, .40, .49]
            data = [[Paragraph(inline(c), styles['header'] if r == 0 else styles['cell']) for c in row] for r, row in enumerate(rows)]
            table = Table(data, colWidths=[doc.width * x for x in ratios], repeatRows=1, hAlign='LEFT')
            table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),FOREST),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,PAPER]),('GRID',(0,0),(-1,-1),.5,LINE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]))
            story += [table, Spacer(1, 12)]; continue
        if line.startswith('- ') or re.match(r'^\d+\. ',line):
            story.append(Paragraph(inline(line), styles['body'])); i += 1; continue
        paragraph = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].strip().startswith(('#','|','- ')):
            paragraph.append(lines[i].strip()); i += 1
        story.append(Paragraph(inline(' '.join(paragraph)), styles['body']))

    def chrome(canvas, current_doc):
        width, height = A4
        canvas.saveState()
        if current_doc.page == 1:
            canvas.setFillColor(PAPER); canvas.rect(0, 0, width, height, fill=1, stroke=0)
            canvas.setStrokeColor(colors.HexColor('#D9E0CF')); canvas.setLineWidth(.7)
            for ring in range(11):
                canvas.ellipse(width - 236 + ring*5, height - 256 + ring*5, width + 40 - ring*5, height + 20 - ring*5, stroke=1, fill=0)
        canvas.setFont('Helvetica',8)
        canvas.setFillColor(MUTED)
        canvas.drawString(49, height - 34, 'HEADLY  /  PRODUCT REQUIREMENTS')
        canvas.drawRightString(width - 49, height - 34, 'VERSION 1.0')
        canvas.setFont('Helvetica',8)
        canvas.drawString(49, 30, 'HEADLY')
        canvas.drawRightString(width - 49, 30, f'{current_doc.page:02d}')
        canvas.restoreState()
    doc.build(story, onFirstPage=chrome, onLaterPages=chrome)
    print(output)


if __name__ == '__main__': main()
