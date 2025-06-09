<!-- TOP -->
<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/cmd8/ff-bifbox">
    <img src="logo.svg" alt="Logo" width="400" height="100">
  </a>

  <p align="center">
    A bifurcation analysis toolbox built for FreeFEM.
    <br />
    <a href="https://github.com/cmd8/ff-bifbox/issues">Report Bug</a>
    ·
    <a href="https://github.com/cmd8/ff-bifbox/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

ff-bifbox is a package of scalable and cross-compatible FreeFEM scripts designed for numerical continuation, bifurcation analysis, resolvent analysis, and time-integration of large-scale time-dependent nonlinear PDEs on adaptively refined meshes. The project is built on top of [FreeFEM](https://freefem.org/), a free, open-source finite-element software, and [PETSc](https://petsc.org/), a scalable scientific computing library.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started
### Prerequisites
Make sure you have access to a recent [FreeFEM](https://freefem.org/) installation (version 4.14 or above), compiled with the `PETSc` and `PETSc-complex` **(with SLEPc)** plugins. Guides for compiling FreeFEM with PETSc can be found on the [FreeFEM GitHub page](https://github.com/FreeFem/FreeFem-sources) or in [this tutorial](https://joliv.et/FreeFem-tutorial/) by Pierre Jolivet. More details about the [PETSc](https://petsc.org/release/docs/manual/) and [SLEPc](http://slepc.upv.es/documentation/slepc.pdf) options used in the solvers may be found in their respective manuals.

### Installation

1. Clone the repo
   ```bash
   git clone https://github.com/cmd8/ff-bifbox.git
   ```
2. Add `ff-bifbox` to FreeFEM's filepath

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

See the [examples](https://github.com/cmd8/ff-bifbox/tree/main/examples) folder.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ROADMAP -->
## Roadmap

- [x] Add linear resolvent analysis framework
- [x] Add time-domain nonlinear simulation framework
- [x] Add support for 3-D problems with multiple symmetries
- [x] Add harmonic balance framework for computation/continuation of periodic orbits
- [x] Add time-domain linear simulation framework
- [x] Add Floquet analysis for periodic orbits
- [ ] Add fold/Neimark-Sacker bifurcation computation/continuation for periodic orbits
- [ ] Add resolvent analysis for periodic orbits
- [ ] Improve documentation and tutorials/examples
- [ ] Release first stable version


See the [open issues](https://github.com/cmd8/ff-bifbox/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the GPL-3.0 License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Chris Douglas - christopher.douglas@duke.edu

Project Link: [https://github.com/cmd8/ff-bifbox](https://github.com/cmd8/ff-bifbox)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Pierre Jolivet](https://joliv.et/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
