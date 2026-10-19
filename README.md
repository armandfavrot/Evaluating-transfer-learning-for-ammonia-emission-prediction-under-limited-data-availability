# Evaluating transfer learning for ammonia emission prediction under limited data availability
Armand Favrot, Sophie Génermont, Vincent Guigue, Céline Décuq, David Makowski
2026-09-23

### Citation

Submitted to Computo.

### Badges

[![build and
publish](https://github.com/armandfavrot/Evaluating-transfer-learning-for-ammonia-emission-prediction-under-limited-data-availability/actions/workflows/build.yml/badge.svg)](https://github.com/armandfavrot/Evaluating-transfer-learning-for-ammonia-emission-prediction-under-limited-data-availability/actions/workflows/build.yml)
[![reviews](https://img.shields.io/badge/review-report-blue)](https://github.com/armandfavrot/Evaluating-transfer-learning-for-ammonia-emission-prediction-under-limited-data-availability/issues?q=is:open is:issue label:review)
[![SWH](https://archive.softwareheritage.org/badge/origin/https://github.com/armandfavrot/Evaluating-transfer-learning-for-ammonia-emission-prediction-under-limited-data-availability)](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/armandfavrot/Evaluating-transfer-learning-for-ammonia-emission-prediction-under-limited-data-availability)
[![DOI:**?meta:citation.doi**](https://img.shields.io/badge/DOI--034E79.svg)](https://doi.org/?meta:citation.doi)
[![Creative Commons
License](https://i.creativecommons.org/l/by/4.0/80x15.png)](http://creativecommons.org/licenses/by/4.0/)

### Authors’ affiliations

- Armand Favrot (Université Paris-Saclay, INRAE, AgroParisTech, UMR EcoSys, Palaiseau, 91120, France, Université Paris-Saclay, INRAE, AgroParisTech, UMR MIA-PS, Palaiseau, 91120, France)
- Sophie Génermont (Université Paris-Saclay, INRAE, AgroParisTech, UMR EcoSys, Palaiseau, 91120, France)
- Vincent Guigue (Université Paris-Saclay, INRAE, AgroParisTech, UMR MIA-PS, Palaiseau, 91120, France)
- Céline Décuq (Université Paris-Saclay, INRAE, AgroParisTech, UMR EcoSys, Palaiseau, 91120, France)
- David Makowski (Université Paris-Saclay, INRAE, AgroParisTech, UMR MIA-PS, Palaiseau, 91120, France)

### Abstract

Because ammonia is a major air pollutant, experimental datasets
describing ammonia emissions following fertilizer application have
expanded considerably over recent decades. However, data availability
remains highly unbalanced across fertilizer types, with abundant
measurements for conventional fertilizers and only limited reliable
observations for emerging products. Transfer learning offers a potential
solution by leveraging knowledge learned from well-documented conditions
to improve predictions under new conditions with scarce data. In this
study, we evaluated whether transfer learning can improve ammonia
emission prediction when only a limited number of reliable measurements
are available in a specific condition of interest. Here, fertilizer
origin was used to define the prediction domains, with cattle and pig
slurries considered alternately as target conditions, while trials from
all other fertilizer origins constituted the corresponding source
domain. The number of available high-quality micrometeorological
measurements in the target domain was artificially restricted. We then
assessed whether recurrent neural networks pretrained on abundant source
domain data and fine-tuned on a small number of target-condition trials
could accurately predict ammonia emissions in the target condition. We
also investigated whether alternative ammonia measurement methods, with
lower reliability, including CaractAir, wind tunnels, dynamic chambers,
and calibrated passive samplers, could improve prediction performance.
Under ten repetitions of five-fold cross-validation, source-domain
pretraining followed by full fine-tuning yielded lower median errors
than training the network directly on target trials at all target sample
sizes examined. However, a target mean predictor remained competitive
for cattle when few target trials were available. Adding an intermediate
fine-tuning stage on alternative-method trials produced modest,
domain-dependent effects: it generally improved median performance for
cattle with wind tunnel, CaractAir, and dynamic chamber data, but tended
to increase errors for pig. Pretraining only on CaractAir or wind tunnel
trials was less effective than combining source-domain pretraining with
sequential fine-tuning. These results support source-domain pretraining
as a useful initialization under limited target-data availability, while
showing that the additional value of alternative-method data depends on
the target domain and adaptation scheme.
