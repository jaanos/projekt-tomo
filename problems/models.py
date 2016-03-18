# -*- coding: utf-8 -*-
from django.contrib.auth.models import User
from django.db import models
from django.template.defaultfilters import slugify


class Language(models.Model):
    name = models.CharField(max_length=70)
    student_file = models.CharField(max_length=70)
    teacher_file = models.CharField(max_length=70)
    extension = models.CharField(max_length=4)

    class Meta:
        ordering = ['name']

    def __unicode__(self):
        return u'{0}'.format(self.name)

    @property
    def mass_file(self):
        return self.student_file.replace("student", "mass")

    @property
    def moss_file(self):
        return self.student_file.replace("student", "moss")

    @property
    def dump_file(self):
        return self.student_file.replace("student", "dump")


class Problem(models.Model):
    author = models.ForeignKey(User, related_name='problems')
    language = models.ForeignKey(Language, related_name='problems')
    title = models.CharField(max_length=70)
    description = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now=True)
    preamble = models.TextField(blank=True)
    problem_set = models.ForeignKey('courses.ProblemSet',
                                    related_name='problems')

    class Meta:
        order_with_respect_to = 'problem_set'

    def __unicode__(self):
        return u'{0}'.format(self.title)

    def save(self, *args, **kwargs):
        self.problem_set.save()
        super(Problem, self).save(*args, **kwargs)

    def filename(self):
        return u'{0}.{1}'.format(slugify(self.title), self.language.extension)

    def get_absolute_url(self):
        return "{0}#problem-{1}".format(self.problem_set.get_absolute_url(),
                                        self.id)

    def preamble_for(self, user):
        if user.is_authenticated():
            try:
                sub = user.submissions.filter(
                    problem=self
                ).latest('timestamp')
                preamble = sub.preamble
            except:
                preamble = u"\n{0}\n".format(self.preamble)
        else:
            preamble = u"\n{0}\n".format(self.preamble)
        return preamble


class Part(models.Model):
    problem = models.ForeignKey(Problem, related_name='parts')
    description = models.TextField(blank=True)
    solution = models.TextField(blank=True)
    validation = models.TextField(blank=True)
    challenge = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now=True)

    class Meta:
        order_with_respect_to = 'problem'

    def __unicode__(self):
        return u'#{0} ({1})'.format(self._order + 1, self.id)

    def save(self, *args, **kwargs):
        self.problem.save()
        super(Part, self).save(*args, **kwargs)
