#!/usr/bin/env python

from HTMLParser import HTMLParser

works = []

workEntryTemplate = [
    "<owl:NamedIndividual rdf:about='&renata;FOAF-modified#",#id    (ex:Electronic_Digital_Image_Stabilization:_Design_and_Evaluation,_with_Applications)
    "'>\n\t<rdf:type rdf:resource='&renata;FOAF-modified#Thesis'/>\n\t <documentTitle>",# name (ex:Electronic_Digital_Image_Stabilization:_Design_and_Evaluation,_with_Applications)
        "</documentTitle>\n\t <publicationYear rdf:datatype='&xsd;integer'>", #date (ex 1997)
        "</publicationYear>\n\t <supervisedBy rdf:resource='&renata;FOAF-modified#",#supervisor (ex:Rama_Chellappa)
        "'/>\n\t",
        "<writtenBy rdf:resource='&renata;FOAF-modified#",#author (ex:Jose_da_Silva)
        "'/>\n\t",
        "<writerOf rdf:resource='&renata;FOAF-modified#",#id (ex:Jose_da_Silva)
        "'/>\n",
        "</owl:NamedIndividual>\n\n"]

def populateOntologyWorks():
    output = open("populado2.owl","w")
    for w in works:
        name = "_".join(w.title.split(' '))
        output.write (workEntryTemplate[0]+name+workEntryTemplate[1]+name)
        output.write (workEntryTemplate[2]+str(w.date))
        for s in w.superv:
            s = "_".join(s.split(' '))
            output.write (workEntryTemplate[3]+s+workEntryTemplate[4])
        author = "_".join(w.student.split(' '))
        output.write (workEntryTemplate[5]+author+workEntryTemplate[6])
        output.write (workEntryTemplate[7]+name+workEntryTemplate[8])
        output.write (workEntryTemplate[9])

def MergeOnthologies():
    lastLine = "</rdf:RDF>"
    onto1 = open("populado.owl", "r")
    onto2 = open("populado2.owl", "r")
    ontoFinal = open("populadoFinal.owl", "w")
    l = onto1.readline()
    while True:
        l2 = onto1.readline()
        if not l2:
            break
        ontoFinal.write(l)
        l = l2
    while True:
        l = onto2.readline()
        if not l:
            break
        ontoFinal.write(l)
    ontoFinal.write(lastLine)


class Work():
    student = ""
    superv = []
    title = ""
    def __init__(self):
        self.student = ""
        self.superv = []

def IsNumber(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

class Parser (HTMLParser):
    alguem = False
    currentTag = ""
    currentEntry = None
    endedUsefulData = False
    def handle_starttag (self, tag, attrs):
        self.currentTag = tag
        if tag == "table":
            self.endedUsefulData = False
            
        if tag == "td":
            self.currentEntry = Work ()
            return
        if tag == "a":
          for a in attrs:
                if "lattes" in a[1]:
                    self.alguem = True
    def handle_endtag (self, tag):
        if tag == "table":
            self.endedUsefulData = True
        if tag == "td":
            if not self.currentEntry.student == "":
                works.append(self.currentEntry)
            self.currentEntry = None
    def handle_data (self, data):
        if self.endedUsefulData:
            return
        if self.currentTag == "b" and not self.currentEntry == None and self.currentEntry.title == "":
            if data[0] == ".":
                data = "No Title"
            self.currentEntry.title = data
            #print "Found work: ", data
        ##print data
        if "cio:" in data:
            try:
                i = data.index(":")
                date = int(data[i+2:i+6]) 
                self.currentEntry.date = date
                #print "date found:",str(date)
            except Exception as exc:
                print exc.args
        if self.currentTag == "td" and not self.currentEntry == None:
            if self.currentEntry.student == "" and not IsNumber(data[0]):
                try:
                    self.currentEntry.student = data[0:-2]
                    #print "Found student:",data
                except Exception as exc:
                    print exc.args
        if self.alguem:
            if self.currentEntry.student == "":
                self.currentEntry.student = data
                #print "Found student:",data
            else:
                if not data in self.currentEntry.superv:
                    self.currentEntry.superv.append(data)
                    #print "Found supervisor:",data
            self.alguem = False


# instantiate the parser
# and fed it some HTML
def ExtractedData():
    output = open("data.log",'w')
    for w in works:
        output.write("---------------------------------------------------------------------\n")
        output.write("Student: "+w.student+"\n")
        output.write("Title: "+w.title+"\n")
        output.write("Date: "+str(w.date)+"\n")
        for s in w.superv:
            output.write("Supervisor: "+s+"\n")

parser = Parser()
html = open("OA-0.html",'r')
parser.feed(html.read())
populateOntologyWorks()
MergeOnthologies()
