#tag Class
Protected Class UINewsViewer
Inherits DesktopHTMLViewer
	#tag Event
		Sub DocumentComplete(url as String)
		  me.Reload
		  
		  RaiseEvent DocumentComplete URL
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub AddArticleToDictionary(append As Boolean, articleLink As String, articleTitle As String, articleBody As String, articleAuthor As String, articleDate As String, articleEnclosureLink As String, articleEnclosureFilename As String, feedTitle As String, feedLink As String, feedDescription As String)
		  DIM article As NEW Dictionary
		  article.Value("articleLink") = me.Escape(articleLink)
		  article.Value("articleTitle") = me.Escape(articleTitle)
		  article.Value("articleBody") = me.Escape(articleBody)
		  article.Value("articleAuthor") = me.Escape(articleAuthor)
		  article.Value("articleDate") = me.Escape(articleDate)
		  article.Value("articleEnclosureLink") = me.Escape(articleEnclosureLink)
		  article.Value("articleEnclosureFilename") = me.Escape(articleEnclosureFilename)
		  article.Value("feedTitle") = me.Escape(feedTitle)
		  article.Value("feedLink") = me.Escape(feedLink)
		  article.Value("feedDescription") = me.Escape(feedDescription)
		  
		  if (me.mArticles.IndexOf(article) = -1) then
		    if (append) then
		      me.mArticles.Append article
		    else
		      me.mArticles.Insert 0, article
		    end if
		  end if
		  
		  me.AddArticleToViewer append, article
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AddArticleToViewer(append As Boolean, data As Dictionary)
		  DIM div As String = me.mTemplate
		  div = div.Replace("$ArticleLink$", data.Value("articleLink"))
		  div = div.Replace("$ArticleTitle$", data.Value("articleTitle"))
		  div = div.Replace("$ArticleBody$", data.Value("articleBody"))
		  div = div.Replace("$ArticleAuthor$", data.Value("articleAuthor"))
		  div = div.Replace("$ArticleDate$", data.Value("articleDate"))
		  div = div.Replace("$ArticleEnclosureLink$", data.Value("articleEnclosureLink"))
		  div = div.Replace("$ArticleEnclosureFilename$", data.Value("articleEnclosureFilename"))
		  div = div.Replace("$FeedTitle$", data.Value("feedTitle"))
		  div = div.Replace("$FeedLink$", data.Value("feedLink"))
		  div = div.Replace("$FeedDescription$", data.Value("feedDescription"))
		  
		  if (append) then
		    me.ExecuteJavaScript "document.getElementById('News').insertAdjacentHTML('beforeend', '" + div + "');"
		  else
		    me.ExecuteJavaScript "document.getElementById('News').insertAdjacentHTML('afterbegin', '" + div + "');"
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AppendArticle(articleLink As String, articleTitle As String, articleBody As String, articleAuthor As String, articleDate As String, articleEnclosureLink As String, articleEnclosureFilename As String, feedTitle As String, feedLink As String, feedDescription As String)
		  me.AddArticleToDictionary TRUE, articleLink, articleTitle, articleBody, articleAuthor, articleDate, articleEnclosureLink, _
		  articleEnclosureFilename, feedTitle, feedLink, feedDescription
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AppendArticle1(articleDIV As String)
		  #Pragma Unused articleDIV
		  'me.ExecuteJavaScript "document.getElementById('News').insertAdjacentHTML('beforeend', '" + articleDIV + "');"
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Clear()
		  REDIM self.mArticles(-1)
		  
		  DIM style As FolderItem
		  style = me.mStyle
		  
		  me.Style = style
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  me.Renderer = 1  // WebKit
		  
		  // Calling the overridden superclass constructor.
		  Super.Constructor
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CreateSource()
		  me.mSource = me.kSourceTemplate
		  
		  // set the base href path
		  me.mSource = me.mSource.Replace("%@", me.mStyle.URLPath)
		  
		  // set the css
		  me.mSource = me.mSource.Replace("%@", me.mStyle.Child("stylesheet.css").URLPath)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Escape(value As String) As String
		  value = value.ReplaceAll("\", "\\")   // slashes
		  value = value.ReplaceAll("""", "\""")  // quotes
		  value = value.ReplaceAll("'", "\'")     // apostrophes
		  value = value.ReplaceAll(Chr(9), " ") // TAB
		  value = ReplaceLineEndings(value, "</br>").ToText
		  
		  Return value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub GrantAccessToFolder(inFolder as FolderItem)
		  #if (TargetMacOS) AND (XojoVersion >= 2020.01) then
		    // copied from https://forum.xojo.com/t/new-problem-with-htmlviewer-loadpage-since-version-2020-r1/56514/7
		    // --- Originally created in July 2020. <--- Leave this info here so it's easier to track which version of the code.
		    //     Published Sep 1st 2020.
		    //     written by Sam Rowlands of Ohanaware.com
		    //     Apple documentation for this API: https://developer.apple.com/documentation/webkit/wkwebview/1414973-loadfileurl?language=objc
		    
		    Declare Function NSClassFromString Lib "Foundation" (inClassName As CFStringRef) As Integer
		    Declare Function NSURLfileURLWithPathIsDirectory Lib "Foundation" Selector "fileURLWithPath:isDirectory:" (NSURLClass As Integer, path As CFStringRef, directory As Boolean) As Integer
		    Declare Function WKWebViewloadFileURL Lib "WebKit" Selector "loadFileURL:allowingReadAccessToURL:" (HTMLViewer As Ptr, URL As Integer, readAccessURL As Integer) As Integer
		    
		    // --- Create a NSURL object from a Xojo Folderitem.
		    DIM folderURL As Integer = NSURLfileURLWithPathIsDirectory(NSClassFromString("NSURL"), inFolder.NativePath, inFolder.Directory)
		    
		    // --- This bit is not technically correct. The first parameter after the instance should actually be the page that you're trying to load.
		    //     But as we're not loading a page per say... For the purpose of just setting access rights, we ignore the return
		    //     value as we don't need to display progress.
		    Call WKWebViewloadFileURL(me.Handle, folderURL, folderURL)
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function OpenAsText(path As FolderItem) As String
		  DIM value As String
		  
		  if (path <> Nil) AND (path.Exists) AND (NOT path.IsFolder) then
		    DIM stream As TextInputStream = TextInputStream.Open(path) //, Xojo.Core.TextEncoding.UTF8)
		    value = stream.ReadAll()
		    stream.Close()
		  end if
		  
		  Return value
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PrependArticle(articleLink As String, articleTitle As String, articleBody As String, articleAuthor As String, articleDate As String, articleEnclosureLink As String, articleEnclosureFilename As String, feedTitle As String, feedLink As String, feedDescription As String)
		  me.AddArticleToDictionary FALSE, articleLink, articleTitle, articleBody, articleAuthor, articleDate, articleEnclosureLink, _
		  articleEnclosureFilename, feedTitle, feedLink, feedDescription
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PrependArticle1(articleDIV As String)
		  #Pragma Unused articleDIV
		  'me.ExecuteJavaScript "document.getElementById('News').insertAdjacentHTML('afterbegin', '" + div + "');"
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Reload()
		  if (me.mArticles.Ubound > -1) then
		    for i as Integer = 0 to me.mArticles.Ubound
		      me.AddArticleToViewer TRUE, me.mArticles(i)
		    next
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ShowArticle(articleLink As String, articleTitle As String, articleBody As String, articleAuthor As String, articleDate As String, articleEnclosureLink As String, articleEnclosureFilename As String, feedTitle As String, feedLink As String, feedDescription As String)
		  me.Clear
		  
		  me.AddArticleToDictionary TRUE, articleLink, articleTitle, articleBody, articleAuthor, articleDate, articleEnclosureLink, _
		  articleEnclosureFilename, feedTitle, feedLink, feedDescription
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DocumentComplete(URL As String)
	#tag EndHook


	#tag Note, Name = 2.0.0
		
		2018-01-26
		• moved out of the FreeLibs module/namespace (this allows it to be used as external code)
		• added .Clear method
		• added .ShowArticle method
	#tag EndNote

	#tag Note, Name = UNLICENSE
		
		This is free and unencumbered software released into the public domain.
		
		Anyone is free to copy, modify, publish, use, compile, sell, or
		distribute this software, either in source code form or as a compiled
		binary, for any purpose, commercial or non-commercial, and by any
		means.
		
		In jurisdictions that recognize copyright laws, the author or authors
		of this software dedicate any and all copyright interest in the
		software to the public domain. We make this dedication for the benefit
		of the public at large and to the detriment of our heirs and
		successors. We intend this dedication to be an overt act of
		relinquishment in perpetuity of all present and future rights to this
		software under copyright law.
		
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
		IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
		OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
		ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
		OTHER DEALINGS IN THE SOFTWARE.
		
		For more information, please refer to <http://unlicense.org>
	#tag EndNote


	#tag Property, Flags = &h21
		Private mArticles() As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSource As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStyle As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTemplate As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mStyle
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  try
			    if (value.IsFolder) then
			      me.mStyle = value
			    elseif (NOT value.IsFolder) AND ((value.Name = "template.html") OR (value.Name = "stylesheet.css")) then
			      me.mStyle = value.Parent
			    else
			      DIM err As NEW Xojo.IO.IOException
			      err.Reason = "Not a valid NewsViewer style."
			      err.Message = "Not a valid NewsViewer style."
			      Raise err
			    end if
			    
			    me.mTemplate = me.OpenAsText(me.mStyle.Child("template.html"))
			    me.mTemplate = me.Escape(me.mTemplate)
			    
			    me.CreateSource
			    
			    me.GrantAccessToFolder me.mStyle
			    me.LoadPage me.mSource, GetTemporaryFolderItem()
			    
			  catch e As Xojo.IO.IOException
			    Raise e
			  end try
			End Set
		#tag EndSetter
		Style As FolderItem
	#tag EndComputedProperty


	#tag Constant, Name = kSourceTemplate, Type = String, Dynamic = False, Default = \"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n<html>\n<head>\n\t<meta http-equiv\x3D\"content-type\" content\x3D\"text/html; charset\x3Dutf-8\" />\n\t<base href\x3D\"%@\">\n\n\t<style type\x3D\"text/css\">\n\t\t.actionMessageUserName { display:none; }\n\t\t.actionMessageBody:before { content:\"*\"; }\n\t\t.actionMessageBody:after { content:\"*\"; }\n\t\t* { word-wrap:break-word; text-rendering: optimizelegibility; }\n\t\timg.scaledToFitImage { height: auto; max-width: 100%%; }\n\t</style>\n\n\t<!-- This style is shared by all variants. !-->\n\t<style id\x3D\"baseStyle\" type\x3D\"text/css\" media\x3D\"screen\x2Cprint\">\n\t\t@import url( \"%@\" );\n\t</style>\n\n</head>\n<body onload\x3D\"initStyle();\" style\x3D\"\x3D\x3DbodyBackground\x3D\x3D\">\n<div id\x3D\"News\">\n</div>\n</body>\n</html>", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kSourceTemplate1, Type = Text, Dynamic = False, Default = \"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n<html>\n<head>\n\t<meta http-equiv\x3D\"content-type\" content\x3D\"text/html; charset\x3Dutf-8\" />\n\t<base href\x3D\"%@\">\n\t<script type\x3D\"text/javascript\" defer\x3D\"defer\">\n\t\t// NOTE:\n\t\t// Any percent signs in this file must be escaped!\n\t\t// Use two escape signs (%%) to display it\x2C this is passed through a format call!\n\t\t\n\t\tfunction appendHTML(html) {\n\t\t\tvar node \x3D document.getElementById(\"Chat\");\n\t\t\tvar range \x3D document.createRange();\n\t\t\trange.selectNode(node);\n\t\t\tvar documentFragment \x3D range.createContextualFragment(html);\n\t\t\tnode.appendChild(documentFragment);\n\t\t}\n\n\t\t// a coalesced HTML object buffers and outputs DOM objects en masse.\n\t\t// saves A LOT of CSS recalculation time when loading many messages.\n\t\t// (ex. a long twitter timeline)\n\t\tfunction CoalescedHTML() {\n\t\t\tvar self \x3D this;\n\t\t\tthis.fragment \x3D document.createDocumentFragment();\n\t\t\tthis.timeoutID \x3D 0;\n\t\t\tthis.coalesceRounds \x3D 0;\n\t\t\tthis.isCoalescing \x3D false;\n\t\t\tthis.isConsecutive \x3D undefined;\n\t\t\tthis.shouldScroll \x3D undefined;\n\n\t\t\tvar appendElement \x3D function (elem) {\n\t\t\t\tdocument.getElementById(\"Chat\").appendChild(elem);\n\t\t\t};\n\n\t\t\tfunction outputHTML() {\n\t\t\t\tvar insert \x3D document.getElementById(\"insert\");\n\t\t\t\tif(!!insert && self.isConsecutive) {\n\t\t\t\t\tinsert.parentNode.replaceChild(self.fragment\x2C insert);\n\t\t\t\t} else {\n\t\t\t\t\tif(insert)\n\t\t\t\t\t\tinsert.parentNode.removeChild(insert);\n\t\t\t\t\t// insert the documentFragment into the live DOM\n\t\t\t\t\tappendElement(self.fragment);\n\t\t\t\t}\n\t\t\t\talignChat(self.shouldScroll);\n\n\t\t\t\t// reset state to empty/non-coalescing\n\t\t\t\tself.shouldScroll \x3D undefined;\n\t\t\t\tself.isConsecutive \x3D undefined;\n\t\t\t\tself.isCoalescing \x3D false;\n\t\t\t\tself.coalesceRounds \x3D 0;\n\t\t\t}\n\n\t\t\t// creates and returns a new documentFragment\x2C containing all content nodes\n\t\t\t// which can be inserted as a single node.\n\t\t\tfunction createHTMLNode(html) {\n\t\t\t\tvar range \x3D document.createRange();\n\t\t\t\trange.selectNode(document.getElementById(\"Chat\"));\n\t\t\t\treturn range.createContextualFragment(html);\n\t\t\t}\n\n\t\t\t// removes first insert node from the internal fragment.\n\t\t\tfunction rmInsertNode() {\n\t\t\t\tvar insert \x3D self.fragment.querySelector(\"#insert\");\n\t\t\t\tif(insert)\n\t\t\t\t\tinsert.parentNode.removeChild(insert);\n\t\t\t}\n\n\t\t\tfunction setShouldScroll(flag) {\n\t\t\t\tif(flag && undefined \x3D\x3D\x3D self.shouldScroll)\n\t\t\t\t\tself.shouldScroll \x3D flag;\n\t\t\t}\n\n\t\t\t// hook in a custom method to append new data\n\t\t\t// to the chat.\n\t\t\tthis.setAppendElementMethod \x3D function (func) {\n\t\t\t\tif(typeof func \x3D\x3D\x3D \'function\')\n\t\t\t\t\tappendElement \x3D func;\n\t\t\t}\n\n\t\t\t// (re)start the coalescing timer.\n\t\t\t//   we wait 25ms for a new message to come in.\n\t\t\t//   If we get one\x2C restart the timer and wait another 10ms.\n\t\t\t//   If not\x2C run outputHTML()\n\t\t\t//  We do this a maximum of 400 times\x2C for 10s max that can be spent\n\t\t\t//  coalescing input\x2C since this will block display.\n\t\t\tthis.coalesce \x3D function() {\n\t\t\t\twindow.clearTimeout(self.timeoutID);\n\t\t\t\tself.timeoutID \x3D window.setTimeout(outputHTML\x2C 25);\n\t\t\t\tself.isCoalescing \x3D true;\n\t\t\t\tself.coalesceRounds +\x3D 1;\n\t\t\t\tif(400 < self.coalesceRounds)\n\t\t\t\t\tself.cancel();\n\t\t\t}\n\n\t\t\t// if we need to append content into an insertion div\x2C\n\t\t\t// we need to clear the buffer and cancel the timeout.\n\t\t\tthis.cancel \x3D function() {\n\t\t\t\tif(self.isCoalescing) {\n\t\t\t\t\twindow.clearTimeout(self.timeoutID);\n\t\t\t\t\toutputHTML();\n\t\t\t\t}\n\t\t\t}\n\n\n\t\t\t// coalased analogs to the global functions\n\n\t\t\tthis.append \x3D function(html\x2C shouldScroll) {\n\t\t\t\t// if we started this fragment with a consecuative message\x2C\n\t\t\t\t// cancel and output before we continue\n\t\t\t\tif(self.isConsecutive) {\n\t\t\t\t\tself.cancel();\n\t\t\t\t}\n\t\t\t\tself.isConsecutive \x3D false;\n\t\t\t\trmInsertNode();\n\t\t\t\tvar node \x3D createHTMLNode(html);\n\t\t\t\tself.fragment.appendChild(node);\n\n\t\t\t\tnode \x3D null;\n\n\t\t\t\tsetShouldScroll(shouldScroll);\n\t\t\t\tself.coalesce();\n\t\t\t}\n\n\t\t\tthis.appendNext \x3D function(html\x2C shouldScroll) {\n\t\t\t\tif(undefined \x3D\x3D\x3D self.isConsecutive)\n\t\t\t\t\tself.isConsecutive \x3D true;\n\t\t\t\tvar node \x3D createHTMLNode(html);\n\t\t\t\tvar insert \x3D self.fragment.querySelector(\"#insert\");\n\t\t\t\tif(insert) {\n\t\t\t\t\tinsert.parentNode.replaceChild(node\x2C insert);\n\t\t\t\t} else {\n\t\t\t\t\tself.fragment.appendChild(node);\n\t\t\t\t}\n\t\t\t\tnode \x3D null;\n\t\t\t\tsetShouldScroll(shouldScroll);\n\t\t\t\tself.coalesce();\n\t\t\t}\n\n\t\t\tthis.replaceLast \x3D function (html\x2C shouldScroll) {\n\t\t\t\trmInsertNode();\n\t\t\t\tvar node \x3D createHTMLNode(html);\n\t\t\t\tvar lastMessage \x3D self.fragment.lastChild;\n\t\t\t\tlastMessage.parentNode.replaceChild(node\x2C lastMessage);\n\t\t\t\tnode \x3D null;\n\t\t\t\tsetShouldScroll(shouldScroll);\n\t\t\t}\n\t\t}\n\t\tvar coalescedHTML;\n\n\t\t//Appending new content to the message view\n\t\tfunction appendMessage(html) {\n\t\t\tvar shouldScroll;\n\n\t\t\t// Only call nearBottom() if should scroll is undefined.\n\t\t\tif(undefined \x3D\x3D\x3D coalescedHTML.shouldScroll) {\n\t\t\t\tshouldScroll \x3D nearBottom();\n\t\t\t} else {\n\t\t\t\tshouldScroll \x3D coalescedHTML.shouldScroll;\n\t\t\t}\n\t\t\tappendMessageNoScroll(html\x2C shouldScroll);\n\t\t}\n\n\t\tfunction appendMessageNoScroll(html\x2C shouldScroll) {\n\t\t\tshouldScroll \x3D shouldScroll || false;\n\t\t\t// always try to coalesce new\x2C non-griuped\x2C messages\n\t\t\tcoalescedHTML.append(html\x2C shouldScroll)\n\t\t}\n\n\t\tfunction appendNextMessage(html){\n\t\t\tvar shouldScroll;\n\t\t\tif(undefined \x3D\x3D\x3D coalescedHTML.shouldScroll) {\n\t\t\t\tshouldScroll \x3D nearBottom();\n\t\t\t} else {\n\t\t\t\tshouldScroll \x3D coalescedHTML.shouldScroll;\n\t\t\t}\n\t\t\tappendNextMessageNoScroll(html\x2C shouldScroll);\n\t\t}\n\n\t\tfunction appendNextMessageNoScroll(html\x2C shouldScroll){\n\t\t\tshouldScroll \x3D shouldScroll || false;\n\t\t\t// only group next messages if we\'re already coalescing input\n\t\t\tcoalescedHTML.appendNext(html\x2C shouldScroll);\n\t\t}\n\n\t\tfunction replaceLastMessage(html){\n\t\t\tvar shouldScroll;\n\t\t\t// only replace messages if we\'re already coalescing\n\t\t\tif(coalescedHTML.isCoalescing){\n\t\t\t\tif(undefined \x3D\x3D\x3D coalescedHTML.shouldScroll) {\n\t\t\t\t\tshouldScroll \x3D nearBottom();\n\t\t\t\t} else {\n\t\t\t\t\tshouldScroll \x3D coalescedHTML.shouldScroll;\n\t\t\t\t}\n\t\t\t\tcoalescedHTML.replaceLast(html\x2C shouldScroll);\n\t\t\t} else {\n\t\t\t\tshouldScroll \x3D nearBottom();\n\t\t\t\t//Retrieve the current insertion point\x2C then remove it\n\t\t\t\t//This requires that there have been an insertion point... is there a better way to retrieve the last element\? -evands\n\t\t\t\tvar insert \x3D document.getElementById(\"insert\");\n\t\t\t\tif(insert){\n\t\t\t\t\tvar parentNode \x3D insert.parentNode;\n\t\t\t\t\tparentNode.removeChild(insert);\n\t\t\t\t\tvar lastMessage \x3D document.getElementById(\"Chat\").lastChild;\n\t\t\t\t\tdocument.getElementById(\"Chat\").removeChild(lastMessage);\n\t\t\t\t}\n\n\t\t\t\t//Now append the message itself\n\t\t\t\tappendHTML(html);\n\n\t\t\t\talignChat(shouldScroll);\n\t\t\t}\n\t\t}\n\n\t\t//Auto-scroll to bottom.  Use nearBottom to determine if a scrollToBottom is desired.\n\t\tfunction nearBottom() {\n\t\t\treturn ( document.body.scrollTop >\x3D ( document.body.offsetHeight - ( window.innerHeight * 1.2 ) ) );\n\t\t}\n\t\tfunction scrollToBottom() {\n\t\t\tdocument.body.scrollTop \x3D document.body.offsetHeight;\n\t\t}\n\n\t\t//Dynamically exchange the active stylesheet\n\t\tfunction setStylesheet( id\x2C url ) {\n\t\t\tvar code \x3D \"<style id\x3D\\\"\" + id + \"\\\" type\x3D\\\"text/css\\\" media\x3D\\\"screen\x2Cprint\\\">\";\n\t\t\tif( url.length )\n\t\t\t\tcode +\x3D \"@import url( \\\"\" + url + \"\\\" );\";\n\t\t\tcode +\x3D \"</style>\";\n\t\t\tvar range \x3D document.createRange();\n\t\t\tvar head \x3D document.getElementsByTagName( \"head\" ).item(0);\n\t\t\trange.selectNode( head );\n\t\t\tvar documentFragment \x3D range.createContextualFragment( code );\n\t\t\thead.removeChild( document.getElementById( id ) );\n\t\t\thead.appendChild( documentFragment );\n\t\t}\n\n\t\t/* Converts emoticon images to textual emoticons; all emoticons in message if alt is held */\n\t\tdocument.onclick \x3D function imageCheck() {\n\t\t\tvar node \x3D event.target;\n\t\t\tif (node.tagName.toLowerCase() !\x3D \'img\')\n\t\t\t\treturn;\n\n\t\t\timageSwap(node\x2C false);\n\t\t}\n\n\t\t/* Converts textual emoticons to images if textToImagesFlag is true\x2C otherwise vice versa */\n\t\tfunction imageSwap(node\x2C textToImagesFlag) {\n\t\t\tvar shouldScroll \x3D nearBottom();\n\n\t\t\tvar images \x3D [node];\n\t\t\tif (event.altKey) {\n\t\t\t\twhile (node.id !\x3D \"Chat\" && node.parentNode.id !\x3D \"Chat\")\n\t\t\t\t\tnode \x3D node.parentNode;\n\t\t\t\timages \x3D node.querySelectorAll(textToImagesFlag \? \"a\" : \"img\");\n\t\t\t}\n\n\t\t\tfor (var i \x3D 0; i < images.length; i++) {\n\t\t\t\ttextToImagesFlag \? textToImage(images[i]) : imageToText(images[i]);\n\t\t\t}\n\n\t\t\talignChat(shouldScroll);\n\t\t}\n\n\t\tfunction textToImage(node) {\n\t\t\tif (!node.getAttribute(\"isEmoticon\"))\n\t\t\t\treturn;\n\t\t\t//Swap the image/text\n\t\t\tvar img \x3D document.createElement(\'img\');\n\t\t\timg.setAttribute(\'src\'\x2C node.getAttribute(\'src\'));\n\t\t\timg.setAttribute(\'alt\'\x2C node.firstChild.nodeValue);\n\t\t\timg.setAttribute(\'width\'\x2C node.getAttribute(\'width\'));\n\t\t\timg.setAttribute(\'height\'\x2C node.getAttribute(\'height\'));\n\t\t\timg.className \x3D node.className;\n\t\t\tnode.parentNode.replaceChild(img\x2C node);\n\t\t}\n\n\t\tfunction imageToText(node)\n\t\t{\n\t\t\tif (client.zoomImage(node) || !node.alt)\n\t\t\t\treturn;\n\t\t\tvar a \x3D document.createElement(\'a\');\n\t\t\ta.setAttribute(\'onclick\'\x2C \'imageSwap(this\x2C true)\');\n\t\t\ta.setAttribute(\'src\'\x2C node.getAttribute(\'src\'));\n\t\t\ta.setAttribute(\'isEmoticon\'\x2C true);\n\t\t\ta.setAttribute(\'width\'\x2C node.getAttribute(\'width\'));\n\t\t\ta.setAttribute(\'height\'\x2C node.getAttribute(\'height\'));\n\t\t\ta.className \x3D node.className;\n\t\t\tvar text \x3D document.createTextNode(node.alt);\n\t\t\ta.appendChild(text);\n\t\t\tnode.parentNode.replaceChild(a\x2C node);\n\t\t}\n\n\t\t//Align our chat to the bottom of the window.  If true is passed\x2C view will also be scrolled down\n\t\tfunction alignChat(shouldScroll) {\n\t\t\tvar windowHeight \x3D window.innerHeight;\n\n\t\t\tif (windowHeight > 0) {\n\t\t\t\tvar contentElement \x3D document.getElementById(\'Chat\');\n\t\t\t\tvar heightDifference \x3D (windowHeight - contentElement.offsetHeight);\n\t\t\t\tif (heightDifference > 0) {\n\t\t\t\t\tcontentElement.style.position \x3D \'relative\';\n\t\t\t\t\tcontentElement.style.top \x3D heightDifference + \'px\';\n\t\t\t\t} else {\n\t\t\t\t\tcontentElement.style.position \x3D \'static\';\n\t\t\t\t}\n\t\t\t}\n\n\t\t\tif (shouldScroll) scrollToBottom();\n\t\t}\n\n\t\twindow.onresize \x3D function windowDidResize(){\n\t\t\talignChat(true/*nearBottom()*/); //nearBottom buggy with inactive tabs\n\t\t}\n\n\t\tfunction initStyle() {\n\t\t\talignChat(true);\n\t\t\tif(!coalescedHTML)\n\t\t\t\tcoalescedHTML \x3D new CoalescedHTML();\n\t\t}\n\t</script>\n\n\t<style type\x3D\"text/css\">\n\t\t.actionMessageUserName { display:none; }\n\t\t.actionMessageBody:before { content:\"*\"; }\n\t\t.actionMessageBody:after { content:\"*\"; }\n\t\t* { word-wrap:break-word; text-rendering: optimizelegibility; }\n\t\timg.scaledToFitImage { height: auto; max-width: 100%%; }\n\t</style>\n\n\t<!-- This style is shared by all variants. !-->\n\t<style id\x3D\"baseStyle\" type\x3D\"text/css\" media\x3D\"screen\x2Cprint\">\n\t\t@import url( \"%@\" );\n\t</style>\n\n</head>\n<body onload\x3D\"initStyle();\" style\x3D\"\x3D\x3DbodyBackground\x3D\x3D\">\n<div id\x3D\"Chat\">\n</div>\n</body>\n</html>", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="InitialParent"
			Visible=false
			Group="Position"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutoDeactivate"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Tooltip"
			Visible=true
			Group="Appearance"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="200"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Renderer"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Native"
				"1 - WebKit"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabIndex"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabPanelIndex"
			Visible=false
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="200"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
